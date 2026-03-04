	export _port_init, _port_getc, _port_getc_timeout
	export _port_putc, _port_putbuf, _port_getbuf
	section code

PORT_BASE	EQU	$FF41
PORT_STATUS	EQU	PORT_BASE+0	; Read status
PORT_GETC	EQU	PORT_BASE+1	; Read data
PORT_CONTROL	EQU	PORT_BASE+0	; Write control	 (same addr, separate R/W)
PORT_PUTC	EQU	PORT_BASE+1	; Write data	 (same addr, separate R/W)

; Status register bit $80 = receive data ready (RDRF)

;;
;; void port_init(void)
;;
_port_init:
	rts

;;
;; int port_getc(void)
;; Returns: D = character (high byte 0) or D = -1 if no char ready
;;
_port_getc:
	lda	PORT_STATUS
	bita	#$02
	bne	gc_have_char	; bit 1 set = data ready
	ldd	#-1
	rts
gc_have_char:
	ldb	PORT_GETC
	lda	#0
	rts

;;
;; int port_getc_timeout(uint16_t timeout)
;; Stack frame: [ret_hi][ret_lo][timeout_hi][timeout_lo]
;; Returns: D = character (high byte 0) or D = -1 on timeout
;;
_port_getc_timeout:
	ldy	2,s
gct_loop:
	lda	PORT_STATUS
	bita	#$02
	bne	gc_have_char	; bit 1 set = data ready (shared with port_getc)
	leay	-1,y
        cmpu    #0
	bne	gct_loop
	ldd	#-1		; Timeout expired
	rts

;;
;; int port_putc(uint8_t c)
;; Stack frame: [ret_hi][ret_lo][c_hi][c_lo]
;; Returns: D = 0
;;
_port_putc:
	ldb	3,s
	stb	PORT_PUTC
	rts

;;
;; uint16_t port_putbuf(const void *buf, uint16_t len)
;; 4,u = buf: pointer to data to transmit
;; 6,u = len: number of bytes to transmit
;; Returns: D = number of bytes written (always == len)
;;
_port_putbuf:
	pshs	y		; preserve Y (required by CMOC convention)
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
;; uint16_t port_getbuf(void *buf, uint16_t len, uint16_t timeout)
;; Stack frame: [ret_hi][ret_lo][buf_hi][buf_lo][len_hi][len_lo][to_hi][to_lo]
;; Returns: D = number of bytes actually read
;;
_port_getbuf:
	pshs	x,y,u
	ldx	8,s
	ldu	10,s
	beq	pgb_done
pgb_next:
	ldy	12,s
pgb_wait:
	lda	PORT_STATUS
	bita	#$02
	bne	pgb_got_char	; bit 1 set = data ready
	leay	-1,y
        cmpu    #0
	bne	pgb_wait
	bra	pgb_done
pgb_got_char:
	lda	PORT_GETC
	sta	,x+
	leau	-1,u
	bne	pgb_next
pgb_done:
	ldd	10,s
	pshs	u
	subd	,s++
	puls	x,y,u
	rts

	end
