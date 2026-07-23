#include "uniflash/menu.h"

uint8_t uf_menu_move_selection(
    uint8_t selected,
    uint8_t item_count,
    uf_menu_move_t movement
)
{
    if (item_count == 0) {
        return 0;
    }
    if (selected >= item_count) {
        selected = 0;
    }
    switch (movement) {
    case UF_MENU_MOVE_UP:
        return selected == 0
            ? (uint8_t)(item_count - 1)
            : (uint8_t)(selected - 1);
    case UF_MENU_MOVE_DOWN:
        return selected + 1 == item_count
            ? 0
            : (uint8_t)(selected + 1);
    case UF_MENU_MOVE_HOME:
        return 0;
    case UF_MENU_MOVE_END:
        return (uint8_t)(item_count - 1);
    default:
        return selected;
    }
}
