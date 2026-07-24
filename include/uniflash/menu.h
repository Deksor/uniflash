#ifndef UNIFLASH_MENU_H
#define UNIFLASH_MENU_H

#include "uniflash/types.h"

typedef enum uf_menu_move {
    UF_MENU_MOVE_UP = 0,
    UF_MENU_MOVE_DOWN,
    UF_MENU_MOVE_HOME,
    UF_MENU_MOVE_END
} uf_menu_move_t;

uint8_t uf_menu_move_selection(uint8_t selected, uint8_t item_count, uf_menu_move_t movement);

#endif
