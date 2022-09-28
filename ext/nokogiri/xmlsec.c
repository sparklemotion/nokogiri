#include <nokogiri.h>

/*
 * This file contains code originally written as part of the xmlsec library.
 *
 * https://www.aleksey.com/xmlsec/
 *
 * Copyright (C) 2002-2022 Aleksey Sanin <aleksey@aleksey.com>. All Rights Reserved.
 */

/* --- taken from include/xmlsec/errors.h --- */
/**
 * xmlSecErrorsSafeString:
 * @str:                the string.
 *
 * Macro. Returns @str if it is not NULL or pointer to "NULL" otherwise.
 */
#define xmlSecErrorsSafeString(str) \
        (((str) != NULL) ? ((const char*)(str)) : (const char*)"NULL")


/* --- taken from src/xmlsec.c --- */
/*
 * Custom external entity handler, denies all files except the initial
 * document we're parsing (input_id == 1)
 */
/* default external entity loader, pointer saved during xmlInit */
static xmlExternalEntityLoader
xmlSecDefaultExternalEntityLoader = NULL;

/*
 * xmlSecNoXxeExternalEntityLoader:
 * @URL:        the URL for the entity to load
 * @ID:         public ID for the entity to load
 * @ctxt:       XML parser context, or NULL
 *
 * See libxml2's xmlLoadExternalEntity and xmlNoNetExternalEntityLoader.
 * This function prevents any external (file or network) entities from being loaded.
 */
xmlParserInputPtr
Nokogiri_xmlSecNoXxeExternalEntityLoader(
  const char *URL,
  const char *ID,
  xmlParserCtxtPtr ctxt
)
{
  if (ctxt == NULL) {
    return (NULL);
  }
  if (ctxt->input_id == 1) {
    return xmlSecDefaultExternalEntityLoader((const char *) URL, ID, ctxt);
  }
  xmlParserError(ctxt, "NONET disallows external entity '%s'\n", xmlSecErrorsSafeString(URL));
  return (NULL);
}


void
noko_init_xmlsec()
{
  if (!xmlSecDefaultExternalEntityLoader) {
    xmlSecDefaultExternalEntityLoader = xmlGetExternalEntityLoader();
  }
}
