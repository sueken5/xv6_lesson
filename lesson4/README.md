# 仮想メモリ

## memlayout.h

PGSIZE		4096byte

KSTKSIZE	(8*PGSIZE)   		// size of a kernel stack
KSTKGAP		(8*PGSIZE)   		// size of a kernel stack guard

ページサイズは4096byte

カーネルスタックのサイズは8*4096

NPTENTRIES	1024 // page table entries per page table

ページテーブルの最初の部分

```
PTSIZE		(PGSIZE*NPTENTRIES) // bytes mapped by a page directory entry
```

ページテーブルのサイズ？4096*1024

User read-only virtual page table

トランスレーション・ルックアサイド・バッファ(TLB)

```
struct PageInfo {
	// Next page on the free list.
	struct PageInfo *pp_link;

	// pp_ref is the count of pointers (usually in page table entries)
	// to this page, for pages allocated using page_alloc.
	// Pages allocated at boot time using pmap.c's
	// boot_alloc do not have valid reference count fields.

	uint16_t pp_ref;
};
```

## pmap.h

```
extern struct PageInfo *pages;
```

これでページテーブルの最初を作って他のファイルから参照できるようにしている

```
typedef uint32_t size_t;
```

```
typedef uint32_t pde_t;
```

pde = page directory entry

```
#define PGNUM(la)	(((uintptr_t) (la)) >> PTXSHIFT)
```
受け取った引数laを`uintptr_t`にキャストしてla/2^12をしている


```
#define PTXSHIFT	12		// offset of PTX in a linear address
```

```
typedef uint32_t uintptr_t;
```

```
static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
}
```

物理ページアドレスをpaとして受け取ってpa/2^12がnpages以上ならアドレスとしておかしいのでパニックしている。もし大丈夫なら0xF0000000+paを返す

```
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
}
```
ポインタ演算をしている。引数に受け取ったppからpagesを引いて、その後に減算結果/2^12した値を返している.


```
static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
}
```

物理アドレスpaを受け取り、`PGNUM(pa)`の値が`npages`より大きい場合はパニック。そうでなければ、`pages`のアドレスからプラス`PGNUM(pa)`したときに存在するPageInfoのポインタを返している。

```
//kvaはkarnel virtual addressの略かと思われる
static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
```

```
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)
```
これの詳細は上に書いといた。

おそらく仮想アドレスを物理アドレスに結びつけているのがこれ。


## pmap.c

```
// These variables are set by i386_detect_memory()
size_t npages;			// Amount of physical memory (in pages)
static size_t npages_basemem;	// Amount of base memory (in pages)

// These variables are set in mem_init()
pde_t *kern_pgdir;		// Kernel's initial page directory
struct PageInfo *pages;		// Physical page state array
static struct PageInfo *page_free_list;	// Free list of physical pages
```

`npages`は物理メモリの量
`npages_basemem`はベースメモリの量 <= ベースメモリってなんぞ？

`kern_pgdir`はカーネルの最初のページディレクトリ。
`pages`は物理ページの状態の配列。配列でもポインタの足し算をすることでなんとかするから配列型じゃない
`page_free_list`は空いてるページのリスト <= 何に使うん？


```
// --------------------------------------------------------------
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
}

static void
i386_detect_memory(void)
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		totalmem, basemem, totalmem - basemem);
}
```

物理メモリの検知に使う関数達

```
static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
}
```

```
unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
}
```

```
#define	IO_RTC		0x070		/* RTC port */
```

`RTC`はリアルタイムクロックの略

`mc146818_read`は引数で受け取った`reg`をリアルタイムクロックに出力している。その後リアルタイムクロックのポート+１に入力されている値を返している。

`nvram_read`は`mc146818_read`から受けた値を返している。

```
static void
i386_detect_memory(void)
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		totalmem, basemem, totalmem - basemem);
}
```

`nvram`はNon-Volatile RAMの略、不揮発性メモリ

`NVRAM_BASELO`は`MC_NVRAM_START + 7`のこと。

```
#define	MC_NVRAM_START	0xe	/* start of NVRAM: offset 14 */
```

```
#define NVRAM_EXTLO	(MC_NVRAM_START + 9)	/* low byte; RTC off. 0x17 */
```

```
#define NVRAM_EXT16LO	(MC_NVRAM_START + 38)	/* low byte; RTC off. 0x34 */
```

```
npages = totalmem / (PGSIZE / 1024);
npages_basemem = basemem / (PGSIZE / 1024);
```

とりあえず、ここら辺で初期化をしている。

`npages`はメモリの合計バイトを４で割った際の値となる。<= npagesはやっぱり使えるページの数ってことになるのかね？
`npages_basemem`は`basemem = nvram_read(NVRAM_BASELO);`で求めた`basemem`を4で割った値になっている。<=何かは全くわからん。なぜにリアルタイムクロックが関係しとるんじゃ？

```
void
mem_init(void)
{
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
	memset(kern_pgdir, 0, PGSIZE);

	//////////////////////////////////////////////////////////////////////
	// Recursively insert PD in itself as a page table, to form
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;

	//////////////////////////////////////////////////////////////////////
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:


	//////////////////////////////////////////////////////////////////////
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();

	check_page_free_list(1);
	check_page_alloc();
	check_page();

	//////////////////////////////////////////////////////////////////////
	// Now we set up virtual memory

	//////////////////////////////////////////////////////////////////////
	// Map 'pages' read-only by the user at linear address UPAGES
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:

	//////////////////////////////////////////////////////////////////////
	// Use the physical memory that 'bootstack' refers to as the kernel
	// stack.  The kernel stack grows down from virtual address KSTACKTOP.
	// We consider the entire range from [KSTACKTOP-PTSIZE, KSTACKTOP)
	// to be the kernel stack, but break this into two pieces:
	//     * [KSTACKTOP-KSTKSIZE, KSTACKTOP) -- backed by physical memory
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	//////////////////////////////////////////////////////////////////////
	// Map all of physical memory at KERNBASE.
	// Ie.  the VA range [KERNBASE, 2^32) should map to
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();

	// Switch from the minimal entry page directory to the full kern_pgdir
	// page table we just created.	Our instruction pointer should be
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));

	check_page_free_list(0);

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
```

これがメモリ管理の核になってる。一個ずつ見てきますよー

```
//////////////////////////////////////////////////////////////////////
// create initial page directory.
kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
memset(kern_pgdir, 0, PGSIZE);
```

ページディレクトリのはじめを作っている。
`kern_pgdir`には`(pde_t *) boot_alloc(PGSIZE)`が入ってる。なので`boot_alloc`には`kern_pgdir`に対応する関数を作ってやらねばならん。
次の`memset`で初期化した`kern_pgdir`から4096バイトを０にしている。なぜかはわからん。
