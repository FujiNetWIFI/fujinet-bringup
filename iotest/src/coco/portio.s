	export _port_init, _port_getc, _port_getc_timeout
	export _port_putc, _port_putbuf, _port_getbuf
	section code

PORT_BASE	EQU	$FF41
PORT_STATUS	EQU	PORT_BASE+0	; Read: status register
PORT_GETC	EQU	PORT_BASE+1	; Read: received byte
PORT_CONTROL	EQU	PORT_BASE+0	; Write: control register
PORT_PUTC	EQU	PORT_BASE+1	; Write: byte to transmit

PIA1_STATUS	EQU	$FF03		; PIA1 side B control/status
VSYNC_FLAG	EQU	$80		; Bit 7 of PIA1_STATUS = VSYNC tick
RDRF_FLAG	EQU	$02		; Bit 1 of PORT_STATUS = receive data ready

; CMOC calling convention (S-relative, no frame pointer in asm functions):
;   Args are pushed right-to-left by caller, caller pops after return.
;   On entry to our asm function, S points at return address.
;   After pshs y (2 bytes), all offsets shift by 2.
;   CMOC requires Y and U to be preserved. D and X may be used freely.

;;
;; void port_init(void)
;;
_port_init:
	rts

;;
;; int port_getc(void)
;; No arguments.
;; Returns: D = character (high byte 0), or D = -1 if no char ready
;;
_port_getc:
	lda	PORT_STATUS	; read status register
	bita	#RDRF_FLAG	; test bit 1: receive data ready?
	beq	gc_no_char	; Z set = bit clear = no char waiting
	ldb	PORT_GETC	; read received byte into B
	lda	#0		; clear A so D = 0x00cc (valid char)
	rts
gc_no_char:
	ldd	#-1		; return -1: no char available
	rts

;;
;; int port_putc(uint8_t c)
;; On entry (no pshs):
;;   0,s = return addr hi
;;   1,s = return addr lo
;;   2,s = c hi (dummy, char promoted to int)
;;   3,s = c lo (actual byte value)
;; Returns: D = 0
;;
_port_putc:
	ldb	3,s		; get low byte of argument (the actual char)
	stb	PORT_PUTC	; transmit is always ready, just write
	ldd	#0		; return 0 for success
	rts

;;
;; uint16_t port_putbuf(const void *buf, uint16_t len)
;; On entry (no pshs yet):
;;   0,s = return addr hi
;;   1,s = return addr lo
;;   2,s = buf hi
;;   3,s = buf lo
;;   4,s = len hi
;;   5,s = len lo
;; After pshs y (2 bytes pushed), add 2 to all offsets:
;;   4,s = buf
;;   6,s = len
;; Returns: D = number of bytes written (always == len)
;;
_port_putbuf:
	pshs	y		; preserve Y
	ldx	4,s		; X = pointer to source buffer
	ldy	6,s		; Y = byte count
	beq	pb_done		; len == 0, nothing to do
pb_loop:
	lda	,x+		; load byte from buffer, advance pointer
	sta	PORT_PUTC	; transmit is always ready, just write
	leay	-1,y		; decrement remaining count
	bne	pb_loop		; loop until Y hits zero
pb_done:
	ldd	6,s		; return original len as bytes written
	puls	y
	rts

;;
;; Internal helper: wait for a character with timeout
;; On entry: Y = timeout tick counter
;; Returns: D = character (high byte 0), or D = -1 on timeout
;; Modifies: A, B, Y
;; Does NOT pshs/puls Y - caller must preserve if needed
;;
_port_getc_wait:
	orcc	#$50		; disable IRQ and FIRQ
gcw_check:
	lda	PORT_STATUS	; check for character first
	bita	#RDRF_FLAG
	bne	gcw_got_char	; got one
	lda	PIA1_STATUS	; check VSYNC
	bpl	gcw_check	; bit 7 clear = no VSYNC, keep checking for char
	lda	$FF02		; read PIA1B data to clear the VSYNC flag
	leay	-1,y		; decrement timeout counter
	beq	gcw_timeout
gcw_wait_low:			; now wait for it to go low before counting again
	lda	PIA1_STATUS
	bmi	gcw_wait_low	; still high, wait
	bra	gcw_check	; gone low, safe to count next rising edge
gcw_timeout:
	andcc	#$AF		; re-enable IRQ and FIRQ
	ldd	#-1		; Z clear, D = -1
	rts
gcw_got_char:
	andcc	#$AF		; re-enable IRQ and FIRQ
	ldb	PORT_GETC
	lda	#0		; Z set, D = char
	rts

;;
;; int port_getc_timeout(uint16_t timeout)
;;
_port_getc_timeout:
	pshs	y
	ldy	4,s		; Y = timeout
	bsr	_port_getc_wait
	puls	y
	rts

;;
;; uint16_t port_getbuf(void *buf, uint16_t len, uint16_t timeout)
;;
_port_getbuf:
	pshs	y
	ldx	4,s		; X = buf
	ldd	6,s		; D = len
	beq	pgb_done
	pshs	d		; push remaining count
				;   0,s = remaining
				;   2,s = saved Y
				;   4,s = return addr
				;   6,s = buf
				;   8,s = len
				;   10,s = timeout
pgb_next:
	ldy	10,s		; Y = timeout (fresh each byte)
	bsr	_port_getc_wait ; returns D = char or -1
	bne	pgb_timeout
	stb	,x+		; store received byte, advance pointer
	ldd	,s		; remaining count
	subd	#1
	std	,s
	bne	pgb_next
pgb_timeout:
pgb_done:
	ldd	8,s		; original len
	subd	,s		; subtract remaining
	leas	2,s		; pop remaining count
	puls	y
	rts
