#include "uniflash/language.h"

#define UF_LANGUAGE(value) static const char english_name[] = value;
#define UF_MESSAGE(id, text)
#include "data/languages/english.def"
#undef UF_MESSAGE
#undef UF_LANGUAGE

#define UF_LANGUAGE(value)
#define UF_MESSAGE(id, text) {(uf_message_id_t)(id), text},
static const uf_language_message_t english_messages[] = {
#include "data/languages/english.def"
};
#undef UF_MESSAGE
#undef UF_LANGUAGE

const uf_language_t uf_language_english = {english_name,
    english_messages,
    (uint16_t)(sizeof(english_messages) / sizeof(english_messages[0]))};

const char *uf_language_get(const uf_language_t *language, uf_message_id_t id) {
    if (language == NULL || id < UF_LANGUAGE_MESSAGE_ID_MIN || id > UF_LANGUAGE_MESSAGE_CAPACITY) {
        return "";
    }
    for (uint16_t index = 0; index < language->message_count; ++index) {
        if (language->messages[index].id == id) {
            return language->messages[index].text;
        }
    }
    return "";
}
