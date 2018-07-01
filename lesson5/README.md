## `ROUNDUP`

```
// Round up to the nearest multiple of n
#define ROUNDUP(a, n)						\
({								\
	uint32_t __n = (uint32_t) (n);				\
	(typeof(a)) (ROUNDDOWN((uint32_t) (a) + __n - 1, __n));	\
})
```

`ROUNDUP`マクロは引数`n`を`uint32_t`型にキャストしてその値を`__n`に代入している。その後`ROUNDDOWN`マクロの引数に`a`を`uint32_t`にキャストしたものプラス、`__n - 1`と、`__n`を渡している。その結果を`a`の型でキャストして、返り値としている。

## `ROUNDDOWN`

```
// Rounding operations (efficient when n is a power of 2)
// Round down to the nearest multiple of n
#define ROUNDDOWN(a, n)						\
({								\
	uint32_t __a = (uint32_t) (a);				\
	(typeof(a)) (__a - __a % (n));				\
})
```

まず引数`a`を`uint32_t`型にキャストして`__a`に代入している。その後、`__a`を`n`で割った値を`__a`から減算して`a`の型にキャストして返している。

## `char`型

c言語では`char`型は1バイトである。

## ポインタ

xv6のワードは32ビット（4バイト）なのでポインタも４バイト

## `boot_alloc`

```
static void *
boot_alloc(uint32_t n)
{
	static char *nextfree;	// virtual address of next byte of free memory
	char *result;

	if (!nextfree) {
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
	}

	cprintf("boot_alloc memory at %x\n", nextfree);
	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
	if (n != 0) {
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	} else return nextfree;

	return NULL;
}
```

引数`n`には`PGSIZE`がきている（4096）。`nextfree`をstatic変数として、`result`を定義している。

```
if (!nextfree) {
  extern char end[];
  nextfree = ROUNDUP((char *) end, PGSIZE);
}
```

一番最初に`boot_alloc`を呼ばれた時はこれが実行される。
`(char *)end`は調べたら`f011d970`だった、何だろうねこれ
`extern char end[];`はカーネルのbssセグメントの最後を示しているらしい。

#### bssセグメント

.bssまたはbssとは、静的にアロケートされた変数のうちプログラムの開始時に0で初期化されているものを含むデータセグメント内の1つのメモリ領域に付けられた名前である。Unix系や Windows を含め、多くのコンパイラやリンカがこの名前を使う。bssセクションあるいはbssセグメントと呼ばれることも多い。

通常、bssセクションに割り当てられたメモリはプログラムローダーがプログラムをロードするときに初期化する。main() が実行されるより前にCランタイムシステムがbssセクションにマップされたメモリ領域をゼロで初期化する。ただし、必要時まで0で初期化するのを遅延するというテクニックを使ってOSがbssセクションを効率的に実装してもよい。

#### nextfreeに入る値を計算

`ROUNDUP(f011d970, 4096)`なので

## static

ローカル変数にstatic修飾子を付けると変数は値を保持し続け、関数を呼び出しても初期化されることはありません。

## ビットAND

ビットANDは演算子の左辺と右辺の同じ位置にあるビットを比較して、両方のビットが共に「1」の場合だけ「1」にします。

## `PDX`

```
// page directory index
#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
```

```
#define PDXSHIFT	22		// offset of PDX in a linear address
```

ページディレクトリは仮想アドレスの上位１０ビットをみて確認している。なので`PDX`は受け取った仮想アドレスを22ビット右に寄せて、アンド演算をする

`0x3FF`は１０進数にすると`1023`になるつまりビットに直すと`1111111111`となる


## `UVPT`

```
// User read-only virtual page table (see 'uvpt' below)
#define UVPT		(ULIM - PTSIZE)
```

よって`ULIM`は4018143232-4194304=4013948928

## `ULIM`

```
#define ULIM		(MMIOBASE)
```

```
// Memory-mapped IO.
#define MMIOLIM		(KSTACKTOP - PTSIZE)
#define MMIOBASE	(MMIOLIM - PTSIZE)
```

```
#define KSTACKTOP	KERNBASE
```

```
// All physical memory mapped at this address
#define	KERNBASE	0xF0000000
```

`0xF0000000`=4026531840

`MMIOLIM`=4026531840-4194304=4022337536
`MMIOBASE`=4022337536-4194304=4018143232


よって`ULIM`は4018143232となる

## `PTSIZE`

```
#define NPTENTRIES	1024		// page table entries per page table

#define PGSIZE		4096		// bytes mapped by a page

#define PTSIZE		(PGSIZE*NPTENTRIES) // bytes mapped by a page directory entry
```

よって`PTSIZE`は4,194,304となる。
