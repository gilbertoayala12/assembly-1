;final.asm
;prints three strings, using functions for repeated tasks
;author: Erick Delfin, Gilberto Ayala, German Verdugo
;date: 2017/05/11

%include '../2.- functions/functions.asm'

segment .data
    msg_file_not_found db "File not found...",0x0
    menu db "*** MENU ***",0xa, "1. Add Student",0xa, "2. Capture Grades",0xa ,"3. Print Students",0xa,"4. Save File",0xa,"0. Quit",0xa,"Option>>>>>> ",0x0
    menu_1 DB "Students name?",0xA,0x0
    menu_2 DB "Waiting for number input...",0xA,0x0
    menu_3 DB "All Students...",0xA,0x0
    menu_4 DB "File Saved!",0xA,0x0
    dummy db "",0xa,0x0
    dummy_space db ",",0x0
    msg_name DB "Students name: ",0x0
    msg_grade DB "Students grade: ",0x0

    msg_empty DB "### No students saved  ###",0x0
    msg_name_file DB "Name file: ",0x0

    space DB " ", 0x0


segment .bss
    students_saved resb 4 ;to keep track of # of students that saved

    array resb 3000
    array_grades resb 3000
    mixed_array resb 4000
    len_mixed equ $-mixed_array
    file_buffer resb 2048
    len equ $-file_buffer
    file resb 2048
    option_buffer resb 3
    option_buffer_len equ $-option_buffer

    grade_buffer resb 8
    grade_buffer_len equ $-grade_buffer

    new_name_buffer resb 30
    len_name equ $-new_name_buffer

section .text
    global _start


_start:
    mov esi, array                                   ;save array direction to esi

    pop ecx                                          ;# of args
    cmp ecx, 2                                       ;check that there's at least 1 arg
    jl no_file

    pop eax                                          ;pop first arg
    dec ecx                                          ;decrement # of args

    ;====== Open file ======
    pop ebx                                          ;file name
    mov eax, sys_open                                ;read operation

    mov ecx, O_RDONLY                                ;O_RDONLY = 0

    int 0x80                                         ;call to system
    cmp eax, 0                                       ;greater than 0
    jle error

    ;====== Read file ======
    mov ebx, eax                                     ;move file handle to ebx
    mov eax, sys_read                                ;read

    mov ecx, file_buffer                                  ;file_buffer direction
    mov edx, len                                     ;file_buffer len

    int 0x80                                         ;call to system


    ;====== Close file ======
    mov eax, sys_close
    int 0x80


    mov eax, file_buffer ;move file contents to eax
    call string_copy_count

;==================== MENU ==========================
    menu_start:
        mov eax, [students_saved]
        call iprintLF       ; imprimir cantidad de nombres actuales (temporal)

        mov eax, menu
        call sprint                                      ;displays menu

        mov ecx, option_buffer                           ;moves option_buffer to ecx for readText function
        mov edx, option_buffer_len                       ;moves option_buffer_len to edx for readText

        call readText
        mov eax, option_buffer
        call atoi                                        ;convert option to int

        cmp eax,1                                        ;compare option to 1 (add student)
        je add_student                                      ;jump if equal

        cmp eax,2                                        ;compare option to 2 (capture grades)
        je capture_grades                                     ;jump if equal

        cmp eax,3                                        ;compare option to 3 (print students)
        je print_student_grades                                      ;jump if equal

        cmp eax,4                                        ;compare option to 4 (save file)
        je save_file                                     ;jump if equal

        cmp eax,0                                        ;compare option to 0 (Quit)
        je end                                           ;jump if equal


        ;=== if any other number is entered, displays menu again ===
        cmp eax, 6
        jge menu_start




    ;====================== Add Student ===============================
    add_student:
        mov eax, msg_name
        call sprint

        ; saves name in eax
        mov ecx, new_name_buffer
        mov edx, len_name
        call readText                                    ;waits for name input
        mov eax, new_name_buffer                             ;saves new_name_buffer to memory in eax


        call stringcopy         
        add esi, 30 ;copies name and moves pointer    
        
        ;update number of names in students_saved
        mov ecx, [students_saved]
        add ecx, 1
        mov [students_saved], ecx

        ;clear the buffer
        mov edi, new_name_buffer
        mov ecx, 30
        xor eax, eax
        rep stosb

        jmp menu_start

    ;====================== Capture Grades ===============================
    capture_grades:
        mov ecx, [students_saved] ;# of studens

        mov esi, array ;student names
        mov edx, array_grades ;student grades

        cycle:
            mov eax, esi
            call sprintLF ;prints student name

            mov eax, msg_grade
            call sprint ;prints msg asking for grade

            push ecx ;push to save registers and use later
            push edx ; =

            mov ecx, grade_buffer
            mov edx, grade_buffer_len ;gets registers ready for input
            call readText ;reads input
            mov eax, grade_buffer ;moves input to eax
            call atoi ;converts grade input to int

            pop edx ;recover array_grades
            mov [edx], eax ;mov grade to array_grades
            add esi, 30 ;for student names
            add edx, 8 ;for grades

            ;clean up buffer
            mov edi, grade_buffer
            mov ecx, 30
            xor eax, eax
            rep stosb

            pop ecx ;recover # of students
            dec ecx ;decrement # of students
            cmp ecx, 0
            jg cycle


        jmp menu_start



    jmp end

    ;====================== Print students and grades =====================

    print_student_grades:

    mov ECX, [students_saved]

    mov ESI, array
    mov EDX, array_grades

        .cycle:
            mov EAX, ESI
            call sprint

            add ESI, 30

            mov EAX, space
            call sprint

            mov EAX, [EDX]
            call iprintLF

            add EDI, 30

            dec ECX
            cmp ECX, 0

            jne .cycle

            jmp menu_start


    save_file:
  
    mov ecx, [students_saved]
    cmp ecx, 0
    je empty_array

                       

    mov esi, mixed_array            
    mov edx, array_grades   
    mov ebx, array                  
    mixed:
        mov eax, ebx                
        call copystring             
        add esi, 30      ;  arrays           
        add ebx, 30         ; arrays 

        mov eax, dummy_space               
        call copystring
        add esi, 1                  

        mov eax, [edx]              
        call itoa  
        ;mov eax, 0xa
        ;call stringcopy
        ;add esi, 1 
        
        add esi, 8 
        add edx, 8
        mov eax, dummy
        call stringcopy
        add esi, 1                  

        
        dec ecx
        cmp ecx, 0

        jne mixed


    ; :saving: ;

    mov eax, msg_name_file
    call sprint                 
    mov ecx, file_buffer        
    mov edx,len            
    call readText               
    mov esi, file               
    mov eax, file_buffer        
    call copystring             

    ; Creating file ;
    mov eax, sys_create        
    mov ebx, file               
    mov ecx, 511                
    int 0x80                    
    cmp eax, 0
    jle error                   

    
    mov eax, sys_open           
    mov ebx, file               
    mov ecx, O_RDWR   

    int 0x80

    cmp eax,0
    jle error                   

    ; Writing :
    mov ebx, eax 


    mov eax, sys_write
    mov ecx, mixed_array             
    mov edx, len_mixed    
    ;;;mov edx, len

    int 0x80
    mov eax, sys_sync           
    int 0x80                    

    mov eax, menu_4
    call sprintLF


    ; :closing: ; 
    mov eax,sys_close   
    int 0x80            
                 
    jmp menu_start



empty_array:
        mov eax, msg_empty
        call sprintLF
        jmp menu_start







string_copy_count:
    mov ebx, 0
    mov ecx, 0
    mov ebx, eax
    pop edx
    
    .next_char:

        mov bl, byte[eax]

        cmp bl, 0 ;if there's still something left
        jz .done

        cmp bl, 0xA ;if its end of line
        je .end_word

        mov byte[esi+ecx], bl   ; moves a char to current index

        inc eax                 ; next letter
        inc ecx                 ; so it doesn't rewrite a char
        jmp .next_char

    .end_word:
        add esi, 30

        inc eax             ; next letter
        inc ecx             ; so it doesn't rewrite a char
        jmp .next_char
        
    .done:              ;restore values
        push edx
        ret




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; rceives integer converts it to ascii (string);;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
itoa:
    push ebx        ; save registers to the stack
    push ecx
    push edx
    push esi

    mov ebx, 10
    mov ecx, 0
    push ecx
    inc ecx

    .divide:
        inc ecx
        mov edx, 0
        idiv ebx
        add edx,0x30
        push edx
        cmp eax, 0
        je .out
        jmp .divide

    .out:
        mov ebx, 0

    .save:
        pop eax
        mov byte[esi+ebx], al
        inc ebx
        cmp ebx, ecx
        jne .save

        pop esi
        pop edx
        pop ecx
        pop ebx 
        ret

no_file:
    mov eax, msg_file_not_found
    call sprintLF
    jmp menu_start

error:
    mov ebx, eax
    mov eax, sys_exit
    int 0x80

end:
    jmp quit
