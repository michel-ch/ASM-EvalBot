



		AREA    |.text|, CODE, READONLY
			
; This register controls the clock gating logic in normal Run ;mode SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf

SYSCTL_PERIPH_GPIO EQU		0x400FE108

; Adresse de base du PIN F
GPIO_PINF_BASE		EQU		0x40025000

; Adresse de base du PIN D
GPIO_PIND_BASE		EQU		0x40007000

; Adresse de base du PIN E
GPIO_PINE_BASE		EQU		0x40024000
	
; configure the corresponding pin to be an output

; all GPIO pins are inputs by default

; GPIO Direction (p417 datasheet de lm3s9B92.pdf

GPIO_O_DIR   		EQU 	0x400



; The GPIODR2R register is the 2-mA drive control register

; By default, all GPIO pins have 2-mA drive.

; GPIO 2-mA Drive Select - p428 datasheet de lm3s9B92.pdf

GPIO_O_DR2R   		EQU 	0x500  



; Digital enable register

; To use the pin as a digital input or output, the ;corresponding GPIODEN bit must be set.

; GPIO Digital Enable - p437 datasheet de lm3s9B92.pdf

GPIO_O_DEN   		EQU 	0x51C  



; Registre pour activer les switchs et les bumpers en logiciel - par d�faut ;ils sont reli�s � la masse donc inactifs

GPIO_PUR			EQU		0x510

; PIN D : selection du SW1 et 2 ,BROCHE 6 et 7 du PORT D

PIN6				EQU     0x40
	
PIN7				EQU		0x80
	
PIN67				EQU		0xC0
	
; PIN F : selection des leds 1 et 2, BROCHE 4 et 5 du PORT F

PIN4				EQU		0x10
	
PIN5				EQU		0x20

PIN45				EQU		0x30

; PIN E : selection du BW1 et 2 ,BROCHE 0 et 1 du PORT E

PIN0				EQU		0x01

PIN1				EQU		0x02

PIN01				EQU 	0x03
	
; d�finit la fr�quence de clignotement
DUREE_CLIGNOTEMENT  EQU     0x0015FFFF
	
; d�finit la dur�e pendant laquelle le robot doit avancer apr�s une rotation
DUREE_AVANCE   		EQU     0x008FFFFF	
	
		ENTRY
		EXPIN	__main
		
		;; The IMPIN command specifies that a symbol is defined in a shared object at runtime.
		IMPIN	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPIN	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPIN  MOTEUR_DROIT_OFF			; d�activer le moteur droit
		IMPIN  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPIN  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arri�re
		IMPIN  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPIN	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPIN  MOTEUR_GAUCHE_OFF			; d�activer le moteur gauche
		IMPIN  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPIN  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arri�re
		IMPIN  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche


__main

; clock sur GPIO F o� sont branch�s les leds, GPIO E sur lequel sont branch�s les bumpers et GPIO D sur lequel sont branch�s les SW : 0x38 == 000111000)
; Enable the PIN F, E and D,  peripheral clock by setting the ;corresponding bits,(p291 datasheet de lm3s9B96.pdf), ;GPIO::HGFEDCBA)	

		ldr r2, = SYSCTL_PERIPH_GPIO  		

        mov r4, #0x00000038  				

	    str r4, [r2]
		  
; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
; tres tres imPINant....;; pas necessaire en simu ou en debbug ;step by step...

		nop	   									
		nop	   
		nop	

;; r0 est utilise pour le moteur
;; r1
;; r2 est horloge systeme puis le compteur de rotations
;; r3 stocke les configurations des Leds, des Switchs et des bumpers
;; r4 stocke les PINs utilises lors de l'initialisation de la configuration
;; r5 est utilise pour stocker la valeur des bumpers
;; r6 est utilise pour le moteur
;; r7 est utilise pour stocker le PIN GPIO des bumpers
;; r8 est utilise pour stocker le PIN GPIO des switches
;; r9 stocke la duree de clignottement
;; r10 est a 0x00 pour eteindre les Leds
;; r11 est utilise pour stocker la valeur des switches
;; r12 allume la Led au PIN correspondant ( PIN 4 ou 5 )

; CONFIGURATION LEDS

		ldr r3, = GPIO_PINF_BASE+GPIO_O_DIR    

; une broche (Pin) du PINF en sortie (broches 4 et 5 : 00110000)

		ldr r4, = PIN45	

		str r4, [r3]

; Configuration du PIN F - Enable Digital Function - PIN F 					

		ldr r3, = GPIO_PINF_BASE+GPIO_O_DEN	

		ldr r4, = PIN45		

		str r4, [r3]

; Choix de l'intensit� de sortie (2mA)			

		ldr r3, = GPIO_PINF_BASE+GPIO_O_DR2R	

        ldr r4, = PIN45			

		str r4, [r3]
		
; Configuration Switchs
		
; Configuration du PIN D - Enable Digital Function - PIN D			

		ldr r3, = GPIO_PIND_BASE+GPIO_O_DEN

        ldr r4, = PIN67	

       	str r4, [r3]			

; Activer le registre des switchs, PIN D			

		ldr r3, = GPIO_PIND_BASE+GPIO_PUR	

       	ldr r4, = PIN67

       	str r4, [r3]
			
; Configuration Bumpers

; Configuration du PIN E - Enable Digital Function - PIN E	

		ldr r3, = GPIO_PINE_BASE+GPIO_O_DEN	

       	ldr r4, = PIN01	

       	str r4, [r3]			


; Activer le registre des bumpers, PIN E		

		ldr r3, = GPIO_PINE_BASE+GPIO_PUR	

       	ldr r4, = PIN01

       	str r4, [r3]
			
			
inst1
; Lecture de l'�tat du SW1 et ranger cet �tat dans r5

			ldr r8,= GPIO_PIND_BASE + (PIN6<<2)

			ldr r11, [r8]

; Si pression sur SW1, alors Evalbot se met � avancer, sinon il ne se passe rien

			cmp	r11,#0x40

			bne	allumemoteur
			
			b inst1
			
			
allumemoteur
		;; BL Branchement vers un lien (sous programme)

		; Configure les PWM + GPIO

		BL	MOTEUR_INIT	   		   
		
		; Activer les deux moteurs droit et gauche

		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON

reset_compteur_rota

		;(re)initialise le compteur de rotations
		mov r2, #0
		
loop	
		; Boucle de pilotage des 2 Moteurs (Evalbot avance)

		BL	MOTEUR_DROIT_AVANT 
		BL	MOTEUR_GAUCHE_AVANT

; Lecture de l'�tat du BW1 et ranger cet �tat dans r5

			ldr r7,= GPIO_PINE_BASE + (PIN0<<2)

			ldr r5, [r7]
			
; Si pression sur BW1 alors Evalbot tourne sur lui m�me dans le sens triginom�trique

			cmp	r5,#0x01

			bne	rota_gauche
       					
; Lecture de l'�tat du BW2 et ranger cet �tat dans r5

			ldr r7,=GPIO_PINE_BASE + (PIN1<<2)

			ldr r5,[r7]

; Si pression sur BW2 alors Evalbot tourne sur lui m�me dans le sens horaire

			cmp r5,#0x02

			bne rota_droite
			
; Lecture de l'�tat du SW2 et ranger cet �tat dans r11 (et non r5 car les 2 composants doivent pouvoir �tre pr�ss�s en m�me temps)
			
			ldr r8,= GPIO_PIND_BASE + (PIN7<<2)

			ldr r11, [r8]
			
; Si pression sur SW2 alors Evalbot s'arr�te

			cmp	r11,#0x80

			bne	stopmoteur

;Si rien d'appuy�, on reste dans la boucle, Evalbot continue d'avancer

			b	loop

rota_droite
		
		; d�finit une rotation � droite
		mov r4, #1
		
		; incr�mente le compteur de rotations
		add r2, #1

		BL	MOTEUR_DROIT_ARRIERE
		
; Allumer la led broche 4 (PIN4)

		mov r10, #0x000       						;; pour eteindre LED
		ldr r12, = PIN4       					;; Allume PINF broche 4 : 00010000
		ldr r3, = GPIO_PINF_BASE + (PIN4<<2)    	;; @data Register = @base + (mask<<2) ==> LED
		mov r6, #0									;; initialise un compteur de clignotement


; CLIGNOTEMENT led 1

clin_d
        	str r10, [r3]    					;; Eteint LED car r2 = 0x00      
        	ldr r9, = DUREE_CLIGNOTEMENT 		;; pour la duree de la boucle d'attente1 (wait1_d)
			add r6, #1							;; incrementation du compteur de clignotement
			cmp r6, #4							;; au bout de 3 clignotements il retourne dans l'�tat o� il avance
			beq avance_d
			b wait1_d
			
avance_d										;; retourne dans loop si le compteur de rotation est pair, c'est � dire si la s�quence avance puis rotation contraire vient de se produire
			cmp r2, #2							
			beq loop
			cmp r2, #4
			beq loop
			cmp r2, #6
			beq loop
			cmp r2, #8
			beq loop
			
			b AVANCE_X_SECONDES					;; autrement effectue la s�quence avance puis rotation contraire


wait1_d		subs r9, #1
        	bne wait1_d

        	str r12, [r3]  					;; Allume PINF broche 4 : 00010000 (contenu de r3)
        	ldr r9, = DUREE_CLIGNOTEMENT	;; pour la duree de la boucle d'attente2 (wait2_d)

wait2_d   	subs r9, #1
        	bne wait2_d
			
; Lecture de l'�tat du SW2 et ranger cet �tat dans r11 

			ldr r8,= GPIO_PIND_BASE + (PIN7<<2)

			ldr r11, [r8]

; Si pression sur SW2 alors Evalbot s'arr�te

			cmp	r11,#0x80

			bne	stopmoteur
			
        	b clin_d
		
rota_gauche
		
		; d�finit une rotation � gauche
		mov r4, #2
		
		; incr�mente le compteur de rotations
		add r2, #1

		BL	MOTEUR_GAUCHE_ARRIERE


; Allumer la led broche 5 (PIN5)

		mov r10, #0x000       						;; pour eteindre LED
		ldr r12, = PIN5       						;; Allume PINF broche 5 : 00010000
		ldr r3, = GPIO_PINF_BASE + (PIN5<<2)    	;; @data Register = @base + (mask<<2) ==> LED
		mov r6, #0									;; initialise un compteur de clignotement


; CLIGNOTEMENT led 2

clin_g
        	str r10, [r3]    					;; Eteint LED car r2 = 0x00      
        	ldr r9, = DUREE_CLIGNOTEMENT 		;; pour la duree de la boucle d'attente1 (wait1_g)
			add r6, #1							;; incrementation du compteur de clignotement
			cmp r6, #4							;; au bout de 3 clignotements il retourne dans l'�tat o� il avance
			beq avance_g
			b wait1_g

avance_g										;; retourne dans loop si le compteur de rotation est pair, c'est � dire si la s�quence avance puis rotation contraire vient de se produire
			cmp r2, #2
			beq loop
			cmp r2, #4
			beq loop
			cmp r2, #6
			beq loop
			cmp r2, #8
			beq loop
			
			b AVANCE_X_SECONDES					;; autrement effectue la s�quence avance puis rotation contraire

wait1_g		subs r9, #1
        	bne wait1_g

        	str r12, [r3]  					;; Allume PINF broche 5 : 00010000 (contenu de r3)
        	ldr r9, = DUREE_CLIGNOTEMENT	;; pour la duree de la boucle d'attente2 (wait2_g)

wait2_g   	subs r9, #1
        	bne wait2_g
			
; Lecture de l'�tat du SW2 et ranger cet �tat dans r11 

			ldr r8,= GPIO_PIND_BASE + (PIN7<<2)

			ldr r11, [r8]

; Si pression sur SW2 alors Evalbot s'arr�te

			cmp	r11,#0x80

			bne	stopmoteur
			
        	b clin_g

AVANCE_X_SECONDES

	ldr r9, = DUREE_AVANCE
	
	; fait avancer le robot pendant un temps donn�
	BL	MOTEUR_DROIT_AVANT 
	BL	MOTEUR_GAUCHE_AVANT
	
	cmp r2, #9						;; si le robot a rencontr� 5 fois de suite un obstacle, alors on consid�re que cet obstacle est un mur et le robot reprend sa route
	beq reset_compteur_rota

wait	subs r9, #1
        bne wait

		cmp r4, #1
		beq rota_gauche
		b rota_droite
		
stopmoteur
; Desactiver les moteurs
		BL	MOTEUR_DROIT_OFF
		BL	MOTEUR_GAUCHE_OFF

; �teindre les leds
		str r10, [r3]
		
; Retour dans l'�tat d'attente d'appui sur SW1
		b inst1
		

		BX	LR

		NOP
		
       	END