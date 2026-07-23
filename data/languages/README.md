# Language definitions

This directory will contain one declarative `.def` file per language.
Language data remains compiled into the DOS executable.

Each file will use:

```c
UF_LANGUAGE("English")
UF_MESSAGE(1, "Blanking in progress")
```

Message IDs remain one-based and retain the existing range of 1 through 150.
Missing messages are represented explicitly during translation so outdated
language files cannot silently inherit an incorrect string.

Source files must contain ASCII text only. DOS code-page characters are
written as explicit hexadecimal byte escapes such as `"\x82"`. This prevents
editors or build hosts from silently converting the original DOS encoding.

The yes/no response characters remain part of message 105, matching the
current Pascal behavior.
