; MK14 PONG game created by Milan Humpolik
; All rights remain with the author of this code
; Edited for SBASM compatability by Ian Reynolds Sept 2022
;
; Original Source code available from  http://elektrotest.cz/node/55
; Original YouTube video https://www.youtube.com/watch?v=2hLAX2UUdpk
;
; The game uses the following expansion RAM
; 0x200 - 0x2FF VDU
; 0x300 - 0x3FF VDU
; 0x400 - 0x640 Game code
; 0x700 - Variables
; Game start 0x400

; Where changes have been made to the assembler code, the original is maintained as a comment

	.CR	SCMP
	.TF	PONG.HEX,INT
;	.TF PONG.BIN,bin
	.LF	PONG.LST

#define 	High(x)         (((x) >> 8) & 15)
#define 	Low(x)          ((x) & 255)
#define 	DatPtrD(a)   	((a)-1)
#define 	JS(p,odkaz)      ldi High(DatPtrD(odkaz))\ xpah p\ ldi Low(DatPtrD(odkaz))\ xpal p\ xppc p

; Martine d�ky za tyto definice!

Disp1    	.equ    0300h                   ; horn� polovina obrazu = high half screen
Disp2    	.equ    0200h                   ; doln� polovina obrazu = low half screen
Dataa		.equ	0700h					; lze pouzit puvodni zamer 0880h
HorZnak		.equ	2Dh						; vodorovn� ��ra = horizontal line
BokZnak		.equ	09h						; O9 real   49 sim
Mezera		.equ	20h						; mezern�k =space
PalkaZnak	.equ	3Dh						; rovn�tko =equal
Balon		.equ	0Fh						; OF real  4F sim
Sirka		.equ	16						; ���ka h�i�t� = pitch width
Vyska		.equ	32						; vyska hriste = pitch height
KlavH		.equ	09h						;displej a klavesnice
KlavL		.equ	00h						;0-3 (4bBCD) =O slup 4,5,6,7 = I radek "I/O"
CROMh		.equ	01h						;tabulka p�ekodovani do 7seg
CROMl		.equ	0Bh						; charakter ROM


;--------------offsety-pro-P2-(maximalne 127)------------------------------------------------
Bufer		.equ	0
Citac		.equ	20
PoziceH		.equ	21
PoziceV		.equ	22
RychH		.equ	23						;nepouzito
RychV		.equ	24						;nepouzito
PalPost		.equ	25
Pruchody	.equ	26						;nepouzito
SmerH		.equ	27
SmerV		.equ	28
Zaloha		.equ	29
Obsah		.equ	30
Posun		.equ	31
Radek		.equ	32
Stisknuto	.equ	33
Citac2		.equ	34

			.ORG 	0400h					;0000 pro emul�tor 0400 pro MK14
			NOP								;pouze pro emul�tor
			DINT

;----------------Nastav� prom�nn�----------------------------------------
Zacatek:	LDI Dataa/256    ;LDI High(Dataa)					; Data pointer P2
			XPAH 2
			LDI Dataa\256    ;LDI Low(Dataa)
			XPAL 2
			
			LDI 15
			ST Citac(2)
			ST Pruchody(2)
SmyL:		XAE
			LDI 0
			ST -128(2)
			DLD Citac(2)
			JNZ SmyL
			
			
			
;----------------Sma�e obrazovku-----------------------------------------

ClrScr:		LDI Disp1/256     ;LDI High(Disp1)					; Nastav� aresu LH rohu
			XPAH 1
			LDI 00h
			XPAL 1
			LDI 0h							; cela 1.puka VRAM
			ST Citac(2)
SmyC:		LDI Mezera						; Smy�ka zap�e mezery
			ST  @1(1)
			DLD Citac(2)
			JNZ SmyC
			LDI Disp2/256     ;LDI High(Disp2)					; To sam� pro druhou p�lku
			XPAH 1
			LDI 00h
			XPAL 1
			LDI 0h							; cela 2.puka VRAM
			ST Citac(2)
SmyD:		LDI Mezera						; Smy�ka zap�e mezery
			ST  @1(1)
			DLD Citac(2)
			JNZ SmyD
			JMP Hriste
ZacatekI:	JMP Zacatek
									

;-----------------Vykresl� h�i�t�--------------------------------------
		
	
Hriste:		LDI Disp1/256   ;LDI High(Disp1)					; Nastav� aresu LH rohu
			XPAH 1
			LDI 00h
			XPAL 1
			LDI Sirka						; ���ka h�i�t� do ��ta�e
			ST Citac(2)
SmyA:		LDI HorZnak						; Smy�ka zap�e horn� znaky
			ST  @1(1)
			DLD Citac(2)
			JNZ SmyA
			LDI Disp1/256   ;LDI High(Disp1)
			XPAH 1
			LDI 00h							;lev� mantinel naho�e
			XPAL 1
			JS P3,Boky      ;JS(3,Boky)
			LDI Disp1/256   ;LDI High(Disp1)
			XPAH 1
			LDI 0Fh							;prav� mantinel naho�e
			XPAL 1
			JS P3,Boky      ;JS(3,Boky)
			LDI Disp2/256   ;LDI High(Disp2)					;lev� mantinel dole
			XPAH 1
			LDI 00h
			XPAL 1
			JS P3,Boky      ;JS(3,Boky)
			LDI Disp2/256   ; LDI High(Disp2)					;prav� mantinel dole
			XPAH 1
			LDI 0Fh							;
			XPAL 1
			JS P3,Boky      ;JS(3,Boky)
			
			
			
;---------------Vykresl� p�lku-----------------------------------------------
			LDI 7
			ST PalPost(2)
			JS P3,Palka     ;JS(3,Palka)


;---------------Hlavn� smy�ka------------------------------------------------

Podani:		DLD Pruchody(2)
			JZ ZacatekI
			ST Pruchody(2)
			XAE
			LDI CROMh				
			XPAH 1					
			LDI CROMl
			XPAL 1
			LD -128(1)				;na�te konverzi do 7seg
			ST 0(2)					;ulo�� do bafru zobrazeni
			
cekani:		LDI KlavH				;cist klavesnici
			XPAH 1					;na�te adresu klavesove oblasti
			LDI KlavL
			XPAL 1
			LDI -1
			ST Radek(2)
			LDI 10
			ST Citac(2)
			;LDI 0
			;ST Stisknuto(2)
smyH:		ILD Radek(2)
			XAE
			LD -128(2)					;znaky pro zobrazeni na LED
			ST -128(1)
			DLY 0					;prodleva displej
			LD -128(1)				;precte z E(1)
			XRI 0FFh
			JZ dale6				;dokud neni stisk ceka v cyklu
			LDE
			ANI 0FDh				;je to "2" ? tak start
			JZ start
dale6:		DLD Citac(2)
			JNZ smyH
			JMP cekani
MeziIV:		JMP Podani

start:		LD PalPost(2)				;nastavi startovaci pozici
			ADI 1						;balonu nad stredem palky
			ST PoziceH(2)
			LDI 30d
			ST PoziceV(2)
			LDI 255						;nastavi pocatecni smer na -1
			ST SmerV(2)					;coz je doleva a nahoru
			ST SmerH(2)
SmyG:		JS P3,Adresa       ;JS(3,Adresa)				;vypocita adresu akt. pozice do P1
			LD 0(1)						;a vycte obsah pro obnoveni po
			ST Obsah(2)					;zobrazeni "O" coz je balon
			LDI Balon
			ST 0(1)						;ktery zapise zde na tu pozici
;****************************zpozdovaci usek*************************
; zpozdeni vytvari 20x zobrazovaci smycka LED displeje. Po tu dobu je na pozici	
; zobrazeno "O"			

			LDI KlavH					;cist klavesnici
			XPAH 1						;na�te adresu klavesove oblasti
			LDI KlavL
			XPAL 1
			LDI -1
			ST Radek(2)
			LDI 10
			ST Citac(2)
			LDI 0
			ST Stisknuto(2)
smyJ:		ILD Radek(2)
			XAE
			LD -128(2)					;znak pro displej
			ST -128(1)
			DLY 0					;prodleva displej
			LD -128(1)				;precte z E(1) napr 0111 1111  (kl. 0 -7 )
			XRI 0FFh				;obr�t� na 1000 0000
			JZ nestisk
			ORE						;pricte  adresu sloupce
			ST Stisknuto(2)
nestisk:	DLD Citac(2)
			JNZ smyJ
			LD Stisknuto(2)
			JZ kresba				;nic nestisknuto
			ANI 3
			JZ kresba
			JMP stisk
MeziII:		JMP MeziIV
stisk:		LD Stisknuto(2)
			ANI 7
			CCL
			ADI 0FEh				;prictu -2
			ST Posun(2)				;dostanu 1,0, -1									
vypocet:	LD PalPost(2)			;vypocitat pozici
			CCL
			ADD Posun(2)			; -1, 0, +1
			ST PalPost(2)
			JP testR
			LDI 0
			ST PalPost(2)
			JMP kresba
MeziV:		JMP MeziII
MeziIa:		JMP SmyG
testR:		LD PalPost(2)
			ADI 0F2h				; PP = 12?  (vpravo)
			JNZ kresba
			LDI 13
			ST PalPost(2)
kresba:		JS P3,Palka         ;JS(3,Palka)				;vykreslit
			LDI 0
			ST Posun(2)				;pro jistotu vynulovat posun
			LDI KlavH				;obnovit ukazatel na LED displej
			XPAH 1					
			LDI KlavL
			XPAL 1
			LDI 20					; Delay se zobrazen�m LED displeje
			ST Citac2(2)			; ur�uje rychlost hry
smyN:		LDI -1
			ST Radek(2)
			LDI 10
			ST Citac(2)
			LDI 0
smyM:		ILD Radek(2)
			XAE
			LD -128(2)					;znak pro displej
			ST -128(1)
			DLY 0					;prodleva displej
			DLD Citac(2)
			JNZ smyM
			DLD Citac2(2)
			JNZ smyN

	


;****************************zpozdovaci usek_konec*******************
; po teto dobe, kde se m.j. cte klavesnice se premaze "O" puvodnim
; obsahem, bu� mezera, mantinel nebo p�lka

zkratka:	JS P3,Adresa        ;JS(3,Adresa)			;vypocita adresu akt. souradnice
			LD Obsah(2)				; a p�epise balon puvodnim obsahem pole
			ST 0(1)
			CCL
			LD PoziceV(2)
			ADD SmerV(2)
			JNZ nehore
			LDI 0					;nahore
			ST PoziceV(2)
			LDI 1
			ST SmerV(2)				;dolu se pricita 1
			JMP horizont
MeziI:		JMP MeziIa
nehore:		ST Zaloha(2)
			CCL
			CAI 31
			JNZ nedole
			LD Obsah(2)
			CCL						; vynuluje Carry a porovn�
			CAI 3Ch					; se�te 3Dh -  s doplnkem 3Ch = 0 
			JNZ MeziV				
			
			LDI 30					;dole
			ST PoziceV(2)
			LDI 255					;nahoru se pricita -1
			ST SmerV(2)
			JMP horizont
nedole:		LD Zaloha(2)
			ST PoziceV(2)
			
horizont:	CCL
			LD PoziceH(2)
			ADD SmerH(2)
			JNZ nevlevo
			LDI 0					;vlevo
			ST PoziceH(2)
			LDI 1
			ST SmerH(2)
			JMP MeziI
nevlevo:	ST Zaloha(2)
			CCL
			CAI 15
			JNZ nevpravo
			LDI 14					;vpravo
			ST PoziceH(2)
			LDI 255
			ST SmerH(2)
MeziIII:	JMP MeziI					
nevpravo:	LD Zaloha(2)
			ST PoziceH(2)
			JMP MeziIII
			
	
			
			.db		00h
			
			
;--------------------PODPROGRAMY---------------------------------------------
Boky:		LDI Vyska/2						; po�et ��dk� pro tisk mantinel�
			ST Citac(2)						; do ��ta�e
SmyB:		LDI BokZnak						; z�pis lev�ho mantinelu
			ST  @Sirka(1)
			DLD Citac(2)
			JNZ SmyB
			XPPC 3
			JMP Boky						;nutn� nesmysl

;----------ze sou�adnic vypo��t� adresu a ulo�� do P1------------------------

Adresa:		LD PoziceV(2)					;na�te pozici
			CCL
			CAI 0Fh							;ode�te 16
			JP Spodek						;pozice >15 sko� na spodek
			LD PoziceV(2)					;znovu na�te pozici
			RR								;vyn�sobit 16ti
			RR
			RR
			RR
			ADD PoziceH(2)					;p�i��st horizont�ln� pozici
			XPAL 1
			LDI Disp1/256     ; LDI High(Disp1)					;doplnit horn� bajt horn� poloviny
			XPAH 1
			JMP konecA
Spodek:		RR								;vyn�sobit 16ti
			RR
			RR
			RR
			CCL
			ADD PoziceH(2)					;p�i��st horizont�ln� pozici
			XPAL 1
			LDI Disp2/256     ; LDI High(Disp2)					;doplnit horn� bajt doln� poloviny
			XPAH 1
konecA:		XPPC 3
			JMP Adresa

;----------Palka-------------------------------------------------------------

Palka:		LDI 0F0h						;prvn� pozice vlevo
			XPAL 1
			LDI Disp2/256     ;LDI High(Disp2)
			XPAH 1
			LDI 16d							;pocet znaku mezi mantinely
			ST Citac(2)
SmyE:		LDI Mezera						;vymy�e spodn� ��dku
			ST @1(1)
			DLD Citac(2)
			JNZ SmyE
			LDI Disp2/256     ; LDI High(Disp2)					;pro jistotu znovu
			XPAH 1
			LDI 3							;pocet znaku palky
			ST Citac(2)
			LD PalPost(2)
			ANI 0Fh
			CCL
			ADI 0EFh
			XPAL 1
			LDI 3							;pocet znaku palky
			ST Citac(2)
SmyF:		XAE
			LDI PalkaZnak
			ST -128(1)
			DLD Citac(2)
			JNZ SmyF
			XPPC 3
			JMP Palka


			.END