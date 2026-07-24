#include <assert.h>
#include <string.h>

#include "uniflash/language.h"
#include "uniflash/menu.h"
#include "uniflash/version.h"

int main(void) {
    uint16_t first;
    uint16_t second;

    assert(strcmp(uf_language_english.name, "English") == 0);
    assert(strcmp(UF_VERSION_STRING, "2.00") == 0);
    assert(strcmp(uf_language_get(&uf_language_english, 51), "              Flash ROM chip: ") == 0);
    assert(strcmp(uf_language_get(&uf_language_english, 140), "Compare backup BIOS image with file") == 0);
    assert(strcmp(uf_language_get(&uf_language_english, 14), "") == 0);
    assert(strcmp(uf_language_get(&uf_language_english, 151), "") == 0);
    for (first = 0; first < uf_language_english.message_count; ++first) {
        assert(uf_language_english.messages[first].id >= 1);
        assert(uf_language_english.messages[first].id <= 150);
        assert(uf_language_english.messages[first].text != NULL);
        for (second = first + 1; second < uf_language_english.message_count; ++second) {
            assert(uf_language_english.messages[first].id != uf_language_english.messages[second].id);
        }
    }
    assert(uf_menu_move_selection(0, 7, UF_MENU_MOVE_UP) == 6);
    assert(uf_menu_move_selection(6, 7, UF_MENU_MOVE_DOWN) == 0);
    assert(uf_menu_move_selection(4, 7, UF_MENU_MOVE_HOME) == 0);
    assert(uf_menu_move_selection(2, 7, UF_MENU_MOVE_END) == 6);
    assert(uf_menu_move_selection(9, 7, UF_MENU_MOVE_DOWN) == 1);
    return 0;
}
