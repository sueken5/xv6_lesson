# Memory Management in xv6

> xv6 uses 32-bit virtual addresses, resulting in a virtual address space of 4GB. xv6 uses paging
to manage its memory allocations. However, xv6 does not do demand paging, so there is no
concept of virtual memory.

４ギガの仮想メモリ空間の結果、xv6は32bitの仮想メモリを利用している。xv6はメモリアロケーションの管理の為にページングという技術を利用している。しかし、まだページングは実装されてないので、仮想メモリはまだないのです。

> xv6 uses a page size of 4KB, and a two level page table structure. The CPU register CR3
contains a pointer to the page table of the current running process. The translation from virtual
to physical addresses is performed by the MMU as follows. The first 10 bits of a 32-bit virtual
address are used to index into a page table directory, which points to a page of the inner page
table. The next 10 bits index into the inner page table to locate the page table entry (PTE). The
PTE contains a 20-bit physical frame number and flags. Every page table in xv6 has mappings
for user pages as well as kernel pages. The part of the page table dealing with kernel pages is
the same across all processes.

xv6は１ページを４KBとしていて、二段階のページテーブル構造を使っている。
CR3というレジスタは実際に動いているプロセスのページテーブルのアドレスを持っている。
仮想メモリから物理メモリへの変換は以下に説明するMMU（メモリマネージユニット）によって実現されている。
３２ビットの仮想アドレスの最初の１０ビットはページテーブルディレクトリを指し示す目次（インデックス）として利用されている。ページテーブルディレクトリというのはページテーブルの持つページを指し示すものである。
次の１０ビットはPTEと言われるページテーブルエントリを見つける為にページてブル内に目印となっています。
PTEは２０ビットの物理フレームとフラグを持っています。
xv６の全てのページテーブルはカーネルページと同じようユーザーページ用のマッピングを持っています。
カーネルページを処理するページテーブルの一部は全てのプロセスにおいて共通に使われます。

> In the virtual address space of every process, the kernel code and data begin from KERNBASE
(2GB in the code), and can go up to a size of PHYSTOP (whose maximum value can
be 2GB). This virtual address space of [KERNBASE, KERNBASE+PHYSTOP] is mapped to
[0,PHYSTOP] in physical memory. The kernel is mapped into the address space of every process,
and the kernel has a mapping for all usable physical memory as well, restricting xv6 to
using no more than 2GB of physical memory. Sheets 02 and 18 describe the memory layout of
xv6.

全てのプロセスの仮想アドレス空間の中において、カーネルコードとデータはカーネルベースメモリ層から始まっていて、`PHYSTOP`までの２ギガを占めています。 カーネルベースメモリ層から`PHYSTOP`までの仮想アドレス空間は物理メモリ内で`[0,PHYSTOP]`というように定義されています。
カーネルは全てのプロセスのアドレス空間にマッピングされていて、全ての利用可能な物理メモリへのマッピングを持ち、xv6が物理メモリの２ギガを超えないように制限をしています。
シート２から１８はxv６のメモリレイアウトについて説明します。

> The xv6 bootloader loads the kernel code in low physical memory (starting at 1MB, after leaving
the first 1MB for use by I/O devices), and starts executing the kernel at entry (line 1040).
Initially, there are no page tables or MMU, so virtual addresses must be the same as physical
addresses. So the kernel entry code resides in the lower part of the virtual address space, and the
CPU generates memory references in the low virtual address space only. The entry code first
turns on support for large pages (4MB), and sets up the first page table entrypgdir (lines
1311-1315). The second entry in this page table is easier to follow: it maps [KERNBASE,
KERNBASE+4MB] to[0, 4MB], to enable the first 4MB of kernel code in the high virtual address
space to run after MMU is turned on. The first entry of this page table table maps virtual
addresses [0, 4MB] to physical addresses [0,4MB], to enable the entry code that resides in the
low virtual address space to run. Once a pointer to this page table is stored in CR3, MMU is
turned on, the entry code creates a stack, and jumps to the main function in the kernel’s C code
(line 1217). The C code is located in high virtual address space, and can run because of the
second entry in entrypgdir. So why was the first page table entry required? To enable the
few instructions between turning on MMU and jumping to high address space to run correctly.
If the entry page table only mapped high virtual addresses, the code that jumps to high virtual
addresses of main would itself not run (because it is in low virtual address space).

xv6のブートローダーは物理メモリの低いそう（アドレス的に低いってこと）にカーネルコードをロードします。（０から１MBはI/Oデバイス用に使うので物理メモリの１MBあとからロードします。）
そして、カーネルコードを実行します。
はじめはページテーブルもMMU(メモリマネージユニット)もありません。なので仮想アドレスを物理アドレスと同じようにひとまずは考えときます。
なので、カーネルのエントリーコードは仮想アドレスの低い層（アドレス的に低いという意味）にあります。そして、CPUはとりあえず低い層での仮想アドレスのメモリ参照を行います。カーネルのエントリーコードはまずは４MBのページを対応します、そして初めのページテーブル（これを`entrypgdir`という）をセットします。作られたページテーブルの二つ目のエントリには`[KERNBASE, KERNBASE+4MB]`を仮想メモリ`[0, 4MB]`という風にマッピングしてカーネルコードの初めの４MBをMMUが動いた後に実行できるようにします。
さらに初めのページテーブルの初めのエントリは仮想アドレス`[0, 4MB]`を物理アドレス`[0, 4MB]`にマッピングしてカーネルの仮想アドレスの低い層にあるエントリコードが実行できるようにします。一度初めに作ったページテーブルへのポインタを`CR3`レジスタに保存しておきます。MMUが動き出すとカーネルのエントリーコードはスタックを作り出し、カーネルのメインとなるC言語で書かれたコードを呼び出します。そのコードは仮想アドレスの高い層にあり、`entrypgdir`ないの二つ目のエントリのおかげで実行できるようになります。ではなぜ`entrypgdir`ないの一つ目のエントリが必要なのでしょうか？それはMMUの起動から高アドレス空間に移動する間のガイドに正しく動作できるようにするためです。もしエントリーページテーブルが高仮想アドレス空間のマッピングしかしてなければ、高仮想アドレス空間に移動しようとするカーネルのCコードは実行されないからです。なぜならカーネルコード自体は低仮想アドレス空間にあるからです。

> Remember that once the MMU is turned on, for any memory to be usable, the kernel needs a
virtual address and a page table entry to refer to that memory location. When main starts, it
is still using entrypgdir which only has page table mappings for the first 4MB of kernel
addresses, so only this 4MB is usable. If the kernel wants to use more than this 4MB, it needs
to map all of that memory as free pages into its address space, for which it needs a larger page
table. So, main first creates some free pages in this 4MB in the function kinit1 (line 3030),
which eventually calls the functions freerange (line 3051) and kfree (line 3065). Both
these functions together populate a list of free pages for the kernel to start using for various
things, including allocating a bigger, nicer page table for itself that addresses the full memory

MMUが起動したときのことを考えてみましょう。全てのメモリは利用できないです。カーネルは仮想アドレスとページテーブルエントリーがメモリ検索の為に必要なのです。メイン関数が呼び出されたとき、メイン関数はすでに`entrypgdir`を使っています。そのとき利用される`entrypgdir`はカーネルアドレスの初めの４MBをマッピングしてあるページテーブルをもっています。なのでこの4MBだけが今は使えるのです。もしカーネルが４MBを超えてメモリを利用しようと思ったらカーネルは利用されてないページをアドレススペースとしてマッピングする必要があります。その為にはもっと大きなページテーブルが必要になります。なのでメイン関数はまず４MB中にいくつか利用されてないページをマッピングしています。実際には`freerange`と`kfree`という関数が呼ばれています。二つの関数はカーネルに利用されてないページを集めさせます。
