type rect
	h as integer
	w as integer
	x as integer
	y as integer
end type

type card
	name as string
	kind as string
	pow as integer
	tou as integer
	text as string

	owner as string

	id as integer

	r as rect
	'pic as long
end type

type spell
	name as string
	cost as integer
	text as string

	owner as string

	id as integer
end type

type playertype
	cards as integer
	name as string
	'deck(20) as card
end type

type wintype
	r as rect
	scr as long
end type

type conntype
	ishost as integer
	handle as long
	port as string
	connection as long
end type

const CARD_W = 120
const CARD_H = 200
const CARD_NUM = 5
const HAND_SZ = 2
const STACK_SZ = 10
const TIMELIMIT = 1

dim shared conn as conntype
dim shared padding as double
dim shared offset as integer
dim shared win as wintype
dim shared midcard as card
dim shared stack(STACK_SZ) as spell
dim shared player as playertype
dim shared enemy as playertype
dim shared pics(CARD_NUM) as long

dim shared has_drawn as integer

dim shared stack_index as integer
stack_index = 1

dim shared player_hand(HAND_SZ) as card

dim shared cards(CARD_NUM) as card

dim shared turn as string
dim shared warn_text as string
dim shared warn_time as single

setup
'deckbuild
gameloop

sub gameloop
	do
		Randomize Timer
		_Limit 60
		Pcopy _Display, 1

		paint_cards

		if turn = enemy.name then
			warn "waiting for opponent..."
		end if

		warn_draw
		'draw_logs
		'
		player_turn
		enemy_turn
		explain_card

		if _keydown(ASC("?")) then
			explain_stack
		end if

		_Display
		Pcopy 1, _Display
	loop until checkwin(0) = 1
end sub

sub explain_stack
	cls
	dim pressed as string
	do
		_Limit 60
		Pcopy _Display, 1

		if pressed = "left" and not _KEYDOWN(CVI(CHR$(0) + "K")) then pressed = ""
		if pressed = "right" and not _KEYDOWN(CVI(CHR$(0) + "M")) then pressed = ""
		
		locate 15, 15
		print "Cards in stack: "; stack_index - 1
		
		color _rgb(0,255,255)
		dim i as integer
		locate 1,1
		if stack(i).owner <> player.name then
			print "<<???>>"; " owner: " + stack(i).owner
		else
			describe stack(i).name, stack(i).text, 0, stack(i).cost, "spell", stack(i).owner

			dim p as long
			p = -1
			if stack(i).id <> 0 then p = pics(stack(i).id)
			paint_card win.r.w / 2, win.r.h / 2, CARD_W, CARD_H, p
		end if
		color _rgb(255,255,255)

		IF _KEYDOWN(CVI(CHR$(0) + "K")) and pressed <> "left" then
			i = i - 1   ' left
			pressed = "left"
		end if
		IF _KEYDOWN(CVI(CHR$(0) + "M")) and pressed <> "right" then
			i = i + 1   ' right
			pressed = "right"
		end if
		if i >= stack_index then i = i - 1
		if i < 1 then i = 1

		_Display
		pcopy 1, _display
	loop until _keydown(27)
	cls
end sub

sub endturn
	dim tmp as string
	if midcard.owner = "" then midcard.owner = "none"
	tmp = turn + "|"
	tmp = tmp + midcard.owner + "|"
	tmp = tmp + STR$(midcard.id) + "|" + STR$(stack_index) + "|"
	tmp = tmp + STR$(enemy.cards)
	tmp = tmp + "|" + STR$(player.cards) + "|"
	dim i as integer
	for i = 1 to stack_index - 1
		if stack(i).owner = "" then stack(i).owner = "none"
		tmp = tmp + stack(i).owner + "|"
		tmp = tmp + STR$(stack(i).id) + "|"
		tmp = tmp + STR$(stack(i).cost) + "|"
	next i
	put conn.connection, , tmp
end sub

sub enemy_turn
	if turn <> enemy.name then
		exit sub
	end if

	dim tmp as string
	do
		get conn.connection, , tmp
	loop until tmp <> ""

	dim fst as integer
	dim snd as integer

	fst = instr(tmp, "|")
	turn = left$(tmp, fst - 1)

	snd = instr(fst + 1, tmp, "|") - fst

	midcard.owner = mid$(tmp, fst + 1, snd - 1)
	fst = instr(fst + 1, tmp, "|")
	snd = instr(fst + 1, tmp, "|") - fst

	midcard.id = val(mid$(tmp, fst + 1, snd - 1))
	midcard.name = cards(midcard.id).name
	midcard.text = cards(midcard.id).text
	midcard.pow  = cards(midcard.id).pow
	midcard.tou  = cards(midcard.id).tou
	fst = instr(fst + 1, tmp, "|")
	snd = instr(fst + 1, tmp, "|") - fst

	stack_index = val(mid$(tmp, fst + 1, snd - 1))
	fst = instr(fst + 1, tmp, "|")
	snd = instr(fst + 1, tmp, "|") - fst

	player.cards = val(mid$(tmp, fst + 1, snd - 1))
	fst = instr(fst + 1, tmp, "|")
	snd = instr(fst + 1, tmp, "|") - fst

	enemy.cards = val(mid$(tmp, fst + 1, snd - 1))
	fst = instr(fst + 1, tmp, "|")
	snd = instr(fst + 1, tmp, "|") - fst

	dim i as integer
	for i = 1 to stack_index
		stack(i).owner = mid$(tmp, fst + 1, snd - 1)
		fst = instr(fst + 1, tmp, "|")
		snd = instr(fst + 1, tmp, "|") - fst

		stack(i).id = val(mid$(tmp, fst + 1, snd - 1))
		fst = instr(fst + 1, tmp, "|")
		snd = instr(fst + 1, tmp, "|") - fst

		stack(i).cost = val(mid$(tmp, fst + 1, snd - 1))
		fst = instr(fst + 1, tmp, "|")
		snd = instr(fst + 1, tmp, "|") - fst

		if stack(i).id <> 0 then
			stack(i).name = cards(stack(i).id).name
			stack(i).text = cards(stack(i).id).text
		end if

		if stack(i).owner = "none" then
			stack(i).name = ""
			stack(i).text = ""
			stack(i).owner = ""
			stack(i).cost = 0
			stack(i).id = 0
		end if
	next i
end sub

sub draw_one
	dim i as integer
	if has_drawn <> 1 then
		has_drawn = 1
		for i = 1 to HAND_SZ
			if player_hand(i).name = "" then
				draw_card i
				player.cards = player.cards - 1
				exit for
			end if
		next i
	end if
end sub

sub player_turn
	if turn <> player.name then
		exit sub
	end if

	draw_one
	
	do
		if _MouseButton(2) then
			for i = 1 to HAND_SZ
				if cardhovered(player_hand(i).r.x, player_hand(i).r.y) then
					player_hand(i).name = ""
					player_hand(i).pow = 0
					player_hand(i).tou = 0
					player_hand(i).text = ""
					player_hand(i).owner = ""
					player_hand(i).id = 0
				end if
			next i
		end if
		if _MouseButton(1) then
			for i = 1 to HAND_SZ
				if cardhovered(player_hand(i).r.x, player_hand(i).r.y) and player_hand(i).name <> "" then
					if player_hand(i).kind = "monster" then
						if midcard.name <> "" then
							if midcard.owner = player.name then
								warn "You already have a monster on the field"
								exit for
							end if
							dim tmp as card
							tmp.name = midcard.name
							tmp.pow = midcard.pow
							tmp.tou = midcard.tou
							tmp.text = midcard.text
							if player_hand(i).pow >= midcard.tou then
								if player_hand(i).tou <= midcard.pow then
									midcard.name = ""
									midcard.pow = 0
									midcard.tou = 0
									midcard.text = ""
									midcard.owner = ""
									midcard.id = 0
								else
									midcard.name = player_hand(i).name
									midcard.tou = player_hand(i).tou
									midcard.pow = player_hand(i).pow
									midcard.text = player_hand(i).text
									midcard.owner = player_hand(i).owner
									midcard.id = player_hand(i).id
								end if
								player_hand(i).name = ""
							end if
						else
							midcard.name = player_hand(i).name
							midcard.tou = player_hand(i).tou
							midcard.pow = player_hand(i).pow
							midcard.text = player_hand(i).text
							midcard.owner = player_hand(i).owner
							midcard.id = player_hand(i).id
							player_hand(i).name = ""
						end if
					else
						if stack_index < STACK_SZ then
							stack(stack_index).name = player_hand(i).name
							stack(stack_index).cost = player_hand(i).pow
							stack(stack_index).text = player_hand(i).text
							stack(stack_index).id = player_hand(i).id
							stack(stack_index).owner = player_hand(i).owner
							stack_index = stack_index + 1
								
							player_hand(i).name = ""
							player_hand(i).id = 0
						else
							warn "stack reached max size"
						end if
					end if
				end if
			next i
		end if
	loop while _MouseInput 

	if _keydown(ASC("e")) then
		has_drawn = 0
		turn = enemy.name

		spell_stuff
		endturn
	end if
end sub

sub spell_stuff
	dim i as integer
	dim tmp(STACK_SZ) as spell
	dim alldone as integer
	
	do
		alldone = 1
		for i = stack_index - 1 to 1 step -1
			if stack(i).name <> "" then
				if stack(i).cost <= 0 then
					resolve stack(i).text, stack(i).owner ' here we go :)
					stack(i).name = ""
					alldone = 0
					exit for
				end if
			end if
		next i
	loop until alldone
	
	dim j as integer
	j = 1
	for i = 1 to stack_index - 1
		if stack(i).name <> "" then
			tmp(j).cost = stack(i).cost
			tmp(j).text = stack(i).text
			tmp(j).name = stack(i).name
			tmp(j).id = stack(i).id
			tmp(j).owner = stack(i).owner
			j = j + 1
		end if
	next i

	dim temp as integer
	temp = stack_index
	stack_index = 1
	for i = 1 to temp
		if stack(i).name <> "" then
			stack_index = stack_index + 1
		end if
		stack(i).cost = tmp(i).cost
		stack(i).text = tmp(i).text
		stack(i).name = tmp(i).name
		stack(i).id = tmp(i).id
	next i

	for i = stack_index to 1 step -1
		if stack(i).name <> "" then
			stack(i).cost = stack(i).cost - 1
		end if
	next i
end sub

sub resolve(text as string, owner as string)
	if instr(1, text, "win") then
		if player.name = owner then
			enemy.cards = 0
			player.cards = 20
		else
			enemy.cards = 20
			player.cards = 0
		end if
		dim i as integer
		for i = 1 to stack_index
			stack(i).name = ""
		next i
	end if

	if instr(1, text, "increase") then
		dim ic as integer
		ic = finddigit(text)
		for i = 1 to stack_index
			stack(i).cost = stack(i).cost + ic
		next i
	end if

	if instr(1, text, "destroy") then
		if instr(1, text, "creature") then
			midcard.name = ""
		elseif instr(1, text, "spells") then
			for i = 1 to stack_index
				stack(i).name = ""
			next i
		end if
	end if
end sub

' LMAO this sucks
function finddigit (text as string)
	finddigit = 0
	if instr(1, text, "1") then finddigit = 1
	if instr(1, text, "2") then finddigit = 2
	if instr(1, text, "3") then finddigit = 3
	if instr(1, text, "4") then finddigit = 4
	if instr(1, text, "5") then finddigit = 5
	if instr(1, text, "6") then finddigit = 6
	if instr(1, text, "7") then finddigit = 7
	if instr(1, text, "8") then finddigit = 8
	if instr(1, text, "9") then finddigit = 9
end function

sub warn (text as string)
	warn_text = text
	warn_time = timer
end sub

sub warn_draw
	locate 10,1
	color _rgb(255,255,0)
	print "Spells on stack: "; stack_index - 1
	color _rgb(255,255,255)

	color _rgb(0,255,0)
	print "Cards left: "; enemy.name + ": " + LTRIM$(STR$(enemy.cards)) + " / " + player.name + ": " + LTRIM$(STR$(player.cards))
	color _rgb(255,255,255)

	if warn_text = "" then exit sub
	if timer - warn_time >= 1 then warn_text = ""
	color _rgb(255,0,0)
	print warn_text + "!!"
	color _rgb(255,255,255)
end sub

Function cardhovered (x, y)
    While _MouseInput: Wend
    If _MouseX > x And _MouseX < (x + CARD_W) And _MouseY > y And _MouseY < (y + CARD_H) Then
        cardhovered = 1
    Else
        cardhovered = 0
    End If
End Function

sub paint_card (x, y, w, h, pic)
	if pic = -1 then
		card_frame x, y, w, h
	else
		_putimage (x, y)-(x + w, y + h), pic
	end if
end sub

sub paint_cards
	paint_hand

	dim p as long
	p = -1
	if midcard.id <> 0 then p = pics(midcard.id)
	paint_card midcard.r.x, midcard.r.y, CARD_W, CARD_H, p
end sub

sub paint_hand
	dim i as integer
	dim t as rect
	for i = 1 to HAND_SZ
		t = player_hand(i).r
		dim p as long
		p = -1
		if player_hand(i).id <> 0 then p = pics(player_hand(i).id)
		paint_card t.x, t.y, CARD_W, CARD_H, p
	next i
end sub

sub explain_card
	dim i as integer
	if cardhovered(midcard.r.x, midcard.r.y) then
		describe midcard.name, midcard.text, midcard.tou, midcard.pow, midcard.kind, midcard.owner
	end if
	for i = 1 to HAND_SZ
		if cardhovered(player_hand(i).r.x, player_hand(i).r.y) then
			describe player_hand(i).name, player_hand(i).text, player_hand(i).tou, player_hand(i).pow, player_hand(i).kind, player_hand(i).owner
		end if
	next i
end sub

sub describe (cname as string, text as string, tou as integer, pow as integer, kind as string, owner as string)
	locate 1,1
	if cname = "" then
		print "no card"
		exit sub
	end if
	print "<<"; cname; ">> owner: " + owner
	if kind <> "spell" then
		print "| " + kind + " card, " + _TRIM$(STR$(pow)) + "/" + _TRIM$(STR$(tou)) + " |"
	else
		print "| spell card, cost: " + _TRIM$(STR$(pow)) + " |"
	end if
	print text
end sub

Sub card_frame (x, y, w, h)
	Line (x, y)-(x + w, y + h), , B
End Sub

Sub card_img (x, y, w, h, pic)
    _PutImage (x, y)-(x + w, y + h), pic
End Sub

sub setup
	win.r.w = 800
	win.r.h = 600
	win.scr = _NewImage(win.r.w, win.r.h, 32)

	screen win.scr

	' ask player for a name
	LINE INPUT "Type your name: " ; player.name
	CLS

	dim answ as string
	LINE INPUT "Enter ip (or leave blank to host game): " ; answ

	if answ = "l" then answ = "localhost"
	if answ = "" then
		conn.port = ":7777"
		conn.handle = _openhost("TCP/IP" + conn.port)
		conn.ishost = 1

		if conn.handle >= 0 then
			print "failed to host a game!"
			end
		end if
	else
		conn.port = ":7777:" + answ
		conn.connection = _openclient("TCP/IP" + conn.port)
		conn.ishost = 0

		if conn.connection >= 0 then
			print "failed to enter the game!"
			end
		end if
	end if

	' card parsing
	getcards

	' getting the hand
	padding = 1.2
	offset = 125
	makehand

	' middle card setup
    	midcard.r.x = (win.r.w - CARD_W) / 2
    	midcard.r.y = CARD_H / 2

	' player setup
	player.cards = 20

	' enemy
	cls
	if conn.ishost then
		do
			print "waiting for players"
			conn.connection = _openconnection(conn.handle)
			_delay 1
		loop until conn.connection
		cls
	end if

	put conn.connection, , player.name
	do
		get conn.connection, , enemy.name
	loop until enemy.name <> ""

	put conn.connection, , player.cards
	do
		get conn.connection, , enemy.cards
	loop until enemy.cards > 0

	if conn.ishost then
		dim luck(2) as string
		luck(1) = player.name
		luck(2) = enemy.name
		turn = luck(int(rnd * 2) + 1)
		put conn.connection, , turn
	else
		do
			get conn.connection, , turn
		loop until turn <> ""
	end if

	print "playing against: " + enemy.name
	_delay 1
	cls
	
	if turn = player.name then
		warn "You go first!"
	end if
end sub

sub makehand
	dim i as integer
	for i = 1 to HAND_SZ
		player_hand(i).name = "" ' some cards may ask to draw new hand
		draw_card i

		player_hand(i).r.x = i * padding * CARD_W + offset
		player_hand(i).r.y = win.r.h - CARD_H - 1
	next i
end sub

sub draw_card (slot as integer)
	if player_hand(slot).name = "" then
		dim c as integer
		randomize Timer
		c = INT(rnd * 5) + 1
		player_hand(slot).name = cards(c).name
		player_hand(slot).pow = cards(c).pow
		player_hand(slot).tou = cards(c).tou
		player_hand(slot).text = cards(c).text
		player_hand(slot).kind = cards(c).kind
		player_hand(slot).id = cards(c).id
		player_hand(slot).owner = player.name
	end if
end sub

sub getcards
	dim temp as string
	dim i as integer
	dim j as integer
	i = 1
	j = 1
	open "cards.txt" for input as #1
	do until eof(1)
		line input #1, temp
		if temp = "end card" then
			cards(i).id = i
			i = i + 1
			j = 1
		else
			select case j
				case 1
					cards(i).name = temp
				case 2
					cards(i).kind = temp
				case 3
					cards(i).pow = val(temp)
				case 4
					cards(i).tou = val(temp)
				case 5
					pics(i) = _loadimage(temp)
					if pics(i) = -1 and temp <> "no image" then
						print "failed to load image: '" + temp + "'"
						end
					end if
				case else
					cards(i).text = cards(i).text + CHR$(10) + temp
			end select
			j = j + 1
		end if
	loop
	close #1
end sub

function checkwin (dummy as integer)
	checkwin = 0
	if enemy.cards = 0 and stack_index <= 1 then
		checkwin = 1
	end if
end function

