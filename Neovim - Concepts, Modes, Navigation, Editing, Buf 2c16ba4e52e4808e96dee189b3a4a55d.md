# Neovim - Concepts, Modes, Navigation, Editing, Buffers, Windows, Tabs

## **1. What Neovim actually is**

Neovim is a **modal text editor** (it changes behavior depending on mode).

Instead of clicking around, you **navigate with the keyboard** and move/edit text very precisely.

Think of Neovim as a **command language for text** rather than a typical editor.

---

## **2. Modal editing**

You don’t always “type”. You are in one of multiple modes:

### Normal mode

- Default mode
- Navigate, delete, copy, run commands
- Press `Esc` to return to Normal mode anytime

### Insert mode

- Typing text
- Enter Insert mode using:
    - `i` = insert before cursor
    - `a` = insert after cursor
    - `o` = open a new line below

### Visual mode

- Select text
- Commands apply to selection (delete, copy)
- `v` = select characters
- `V` = select lines
- `Ctrl+v` = block (columns)

### Command mode

- For commands like `:w`, `:q`, `:wq`, etc.
- Trigger with `:`

---

## **3. Fundamental movement**

(Bold means you’ll use it all the time)

Cursor:

- **h j k l** → left, down, up, right
- **w** → next word
- **b** → previous word
- **e** → end of word

Lines:

- **0** → start of line
- **$** → end of line

Pages:

- **gg** → top of file
- **G** → bottom of file
- **Ctrl+d** → half-page down
- **Ctrl+u** → half-page up

Search:

- **/** then text → search
- **n** → next match
- **N** → previous match

---

## **4. Editing fundamentals**

### Text operators

Operator + Motion = Action

- `d` = delete
- `y` = yank (copy)
- `c` = change (delete then insert)

Examples:

- `dw` → delete to next word
- `cw` → change next word
- `d$` → delete to end of line
- `d0` → delete to beginning
- `ci"` → change inside quotes

### Line editing

- **dd** → delete line
- **yy** → copy line
- **p** → paste after
- **P** → paste before

### Undo / redo

- **u** = undo
- **Ctrl+r** = redo

---

## **5. Open / save / quit**

In command mode (`:`):

- `:e filename.cpp` → open
- `:w` → save
- `:q` → quit
- `:wq` → save + quit
- `:q!` → quit without saving

### Shortcuts from our config

- `<leader>w` = save
- `<leader>q` = quit
- `<leader>x` = write+quit
    
    *(leader = Space in our config)*
    

---

## **6. Buffers, Windows, Tabs**

Neovim separates files, viewports, and layouts.

### Buffers (open files)

- `:ls` → list buffers
- `:bn` → next
- `:bp` → previous
- `:bd` → close buffer

Buffers are **files in memory**, not necessarily visible.

---

### Windows (splits)

Windows are viewports on buffers.

- `:sp` → horizontal split
- `:vsp` → vertical split

Our keymaps:

- **Ctrl+h**, **Ctrl+j**, **Ctrl+k**, **Ctrl+l**
    
    (move between windows)
    

---

### Tabs

Tabs are **layouts** of windows (not browser-like).

- `:tabnew`
- `:tabnext`, `:tabprev`
- `:tabclose`

Many experienced users rely mostly on buffers + splits, not tabs.

---

## **7. Visual mode power**

Use Visual mode to select then operate:

- `v` = characters
- `V` = whole line
- `Ctrl+v` = block

Then:

- `d` (delete)
- `y` (copy)
- `>` or `<` (indent)

Example:

- Select lines with `V`
- Press `>` multiple times to indent

---

## **8. Search & replace**

Search:

- `/pattern`

Replace:

```
:%s/old/new/g

```

Add `c` at the end for confirmation:

```
:%s/old/new/gc

```

---

## **9. Numbers + commands**

Almost any movement or action accepts a count:

- `5j` → move down 5 lines
- `3w` → forward 3 words
- `3dd` → delete 3 lines

This is the secret behind vim speed.

---

## **10. Text objects (intermediate but powerful)**

Operate on logical “objects”:

- `iw` (inner word)
- `aw` (a word, including space)
- `i"` (inside quotes)
- `i)` (inside parentheses)
- `ip` (inside paragraph)

Examples:

- `ci"` → change string inside quotes
- `da)` → delete everything around parentheses
- `yap` → yank whole paragraph

This is where vim becomes a weapon.