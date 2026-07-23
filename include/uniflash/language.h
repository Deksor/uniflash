#ifndef UNIFLASH_LANGUAGE_H
#define UNIFLASH_LANGUAGE_H

#include "uniflash/types.h"

#define UF_LANGUAGE_MESSAGE_ID_MIN 1
#define UF_LANGUAGE_MESSAGE_CAPACITY 150

typedef uint16_t uf_message_id_t;

typedef struct uf_language_message {
    uf_message_id_t id;
    const char *text;
} uf_language_message_t;

typedef struct uf_language {
    const char *name;
    const uf_language_message_t *messages;
    uint16_t message_count;
} uf_language_t;

extern const uf_language_t uf_language_english;

const char *uf_language_get(
    const uf_language_t *language,
    uf_message_id_t id
);

UF_STATIC_ASSERT(message_id_is_2_bytes, sizeof(uf_message_id_t) == 2);
UF_STATIC_ASSERT(
    language_message_count_is_2_bytes,
    sizeof(((uf_language_t *)0)->message_count) == 2
);

#endif
