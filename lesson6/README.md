# cr3

page entry directoryのポインタを入れとく

# `PTE_ADDR`

```
#define PTE_ADDR(pte)	((physaddr_t) (pte) & ~0xFFF)
```

受け取った`pte`をビットアンド演算している。

`0xFFF` => `111111111111`で`~`のノットビット演算がかけられているので`000000000000`となる。

やってることは32ビット中のフラグを示す12ビット部分をビットアンド演算している。その結果、返り値は上位20ビットは変わらず、フラグビット部分が`000000000000`になった32ビット群である。

# `KADDR`

```
/* This macro takes a physical address and returns the corresponding kernel
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)
```

受け取った`pa`を`_kaddr`マクロに渡している。その際に`__FILE__`と`__LINE__`も渡している。

```
static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
}
```

返り値として`pa+KERNBASE`を返している。これがページテーブルのポインタを表している。

# `pgdir_walk`

```
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
	// Fill this function in
	// dindexはページディレクトリのPPNをtindexはページテーブルのPPNを表す。
	int dindex = PDX(va), tindex = PTX(va);

	//pgdirのフラグ確認、presentでアンド演算してみて1かどうかをチェック
	if (!(pgdir[dindex] & PTE_P) {
		//createフラグが立っていたらページを新しく生成。
		if (create) {
			struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
			if (!pg) return NULL;	//allocation fails
			pg->pp_ref++;
			pgdir[dindex] = page2pa(pg) | PTE_P | PTE_U | PTE_W;
		} else {
			return NULL;
		}

	}

	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));

	//pにはページテーブルのポインタが入ってるので、そこにtindexを足すことでページテーブルエントリーのポインタが算出できる。
	return p + tindex;
}
```

# `PADDR`

```
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
}
```

物理アドレスを返している。

# `boot_map_region`

```
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	//paは物理アドレス
	//vaは仮想アドレス
	// Fill this function in
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);

	//ページテーブル生成
	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
		//pteにはページテーブルエントリのポインタが入っている
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
		//pteのPresentフラグを１にすることで使えるようにしている。
	}
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);

}
```

# `page2pa`

```
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
}
```

ページを物理アドレスに変換するマクロ

# `page_decref`

```
void
page_decref(struct PageInfo* pp)
{
	if (--pp->pp_ref == 0)
		page_free(pp);
}
```
受け取った`pp`の`pp_ref`が0なら`page_free`

`--pp->pp_ref` <= これどうゆう意味？

# `invlpg`

```
static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}
```

TLBエントリを無効にする。TLBにはページングがキャッシュされているため、これを行わないとパニる
