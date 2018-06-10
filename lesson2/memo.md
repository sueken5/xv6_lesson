# inline asm

```
int main (void)
{
  // 疑似アセンブラ
  // mv  :データの値の移動
  // slli:シフトレフト命令
  // or  :論理or
  // wfs :特殊レジスタからの値のコピー
  // ld  :メモリの値のロード
  // memw:直前までのメモリアクセスが完了するまでストール
  // sub :減算
  // st  :メモリへ値のストア
  asm volatile(
  "mv r0,0x4000;\
   slli r0,16;\
   mv r1,0x8000;\
   or r0, r0, r1;\  …①
   wfs r2, counter;\…②
   ld r1, r0, 0;\
   memw;\           …③
   wfs r3, counter;\…④
   sub r1, r3, r2;\ …⑤
   st r1, r0, 0;"   …⑥
  );

  return 0;
}
```

こんな感じでc言語の中に書ける

# inb

input byte from immediate port into AL	inb $0x7f,%al

alレジスターに値を入れるasm

# /boot/boot.S

おそらく最初に呼ばれていてboot/main.cを呼んでいる

# /boot/main.c

```
ディスクからデータを抜いてメモリに入れている
```

# stack pointer (esp register)

esp registar はスタック用のポインタ

スタックの一番上を示す

# The ebp (base pointer) register,

ebp は スタックの一番底を示す

# eip

命令ポインタ

命令ポインタ (EIP) は、分岐が起きない前提で、次に実行する命令のアドレスを保持している。

EIPはcall命令の直後にのみ読むことができる。

# monitor 関数
init関数で以下呼びだし
```
while (1)
  monitor(NULL);
```

monitor関数でreadlineしてコマンドがきたら反応するようにしている
```
char *buf;

cprintf("Welcome to the JOS kernel monitor!\n");
cprintf("Type 'help' for a list of commands.\n");


while (1) {
  buf = readline("K> ");
  if (buf != NULL)
    if (runcmd(buf, tf) < 0)
      break;
}
```

# c言語 extern

グローバル変数にしている

# memset

memset関数はメモリに指定バイト数分の値をセットすることができます。

```
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
    char buf[] = "ABCDEFGHIJK";
    //先頭から2バイト進めた位置に「１」を3バイト書き込む
    memset(buf+2,'1',3);
    //表示
    printf("buf文字列→%s\n",buf);
    return 0;
}
```

```
buf文字列→AB111FGHIJK
```

# cons_init

```
void
cons_init(void)
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		cprintf("Serial port does not exist!\n");
}
```

これは何をしている

## cga_init

```
static void
cga_init(void)
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
}
```

# memory archtecture

```

+------------------+  <- 0xFFFFFFFF (4GB)
|      32-bit      |
|  memory mapped   |
|     devices      |
|                  |
/\/\/\/\/\/\/\/\/\/\

/\/\/\/\/\/\/\/\/\/\
|                  |
|      Unused      |
|                  |
+------------------+  <- depends on amount of RAM
|                  |
|                  |
| Extended Memory  |
|                  |
|                  |
+------------------+  <- 0x00100000 (1MB)
|     BIOS ROM     |
+------------------+  <- 0x000F0000 (960KB)
|  16-bit devices, |
|  expansion ROMs  |
+------------------+  <- 0x000C0000 (768KB)
|   VGA Display    |
+------------------+  <- 0x000A0000 (640KB)
|                  |
|    Low Memory    |
|                  |
+------------------+  <- 0x00000000
```

 ## Low Memory

 ```
 「低メモリ」と表示された640KBの領域は、初期のPCが使用できる唯一のランダムアクセスメモリ（RAM）でした。実際、非常に初期のPCは、16KB、32KB、または64KBのRAMで構成することしかできませんでした。
 ```

 ## VGA

 VGAは、アナログ信号で PCとディスプレイを接続します。アナログ方式。

古くからある規格で、DVIやHDMIが主流になるまで ほぼすべてのパソコンにこの端子が付いていました。

現在でも 汎用性の高い接続規格として、PC、ディスプレイ、プロジェクターなど様々な機器に付いています。

PCのデジタル情報が、連続的な波であるアナログ信号によって伝送され ディスプレイ表示されます。

## VGA Display

```
ディスプレイなどの為に0x000A0000 ~ 0x000FFFFFFは予約されている。なのでプログラムなので使ってはならない。printするようってことかな？
```

## BIOS ROM

```
この予約領域の最も重要な部分はBIOS（Basic Input / Output System）で、0x000F0000から0x000FFFFFまでの64KB領域を占有します。初期のPCでは、BIOSは真の読み出し専用メモリ（ROM）に保持されていましたが、現在のPCはBIOSを更新可能なフラッシュメモリに格納しています。
```

そもそもBIOSとは

OS（パソコンさんの人格に相当するソフト）が動き出す前のお仕事をやってくれるプログラムのこと

BIOSは、ビデオカードを起動し、インストールされているメモリの容量を確認するなどの基本的なシステム初期化を実行します。この初期化を実行した後、BIOSは、フロッピーディスク、ハードディスク、CD-ROM、またはネットワークなどの適切な場所からオペレーティングシステムをロードし、マシンの制御をオペレーティングシステムに渡します。
