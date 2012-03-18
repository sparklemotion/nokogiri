#ifndef XML_LIBXML2_HACKS
#define XML_LIBXML2_HACKS

#ifndef HAVE_XMLFIRSTELEMENTCHILD

xmlNodePtr xmlFirstElementChild(xmlNodePtr parent);
xmlNodePtr xmlNextElementSibling(xmlNodePtr node);
xmlNodePtr xmlLastElementChild(xmlNodePtr parent);

#endif

#ifndef HAVE_ST_XMLSTRUCTUREDERRORCONTEXT

#define xmlStructuredErrorContext xmlGenericErrorContext

#endif

#endif
