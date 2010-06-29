#ifndef HAVE_XMLFIRSTELEMENTCHILD
/**
 * xmlFirstElementChild:
 * @parent: the parent node
 *
 * Finds the first child node of that element which is a Element node
 * Note the handling of entities references is different than in
 * the W3C DOM element traversal spec since we don't have back reference
 * from entities content to entities references.
 *
 * Returns the first element child or NULL if not available
 */
xmlNodePtr
xmlFirstElementChild(xmlNodePtr parent) {
    xmlNodePtr cur = NULL;

    if (parent == NULL)
        return(NULL);
    switch (parent->type) {
        case XML_ELEMENT_NODE:
        case XML_ENTITY_NODE:
        case XML_DOCUMENT_NODE:
        case XML_HTML_DOCUMENT_NODE:
            cur = parent->children;
            break;
        default:
            return(NULL);
    }
    while (cur != NULL) {
        if (cur->type == XML_ELEMENT_NODE)
            return(cur);
        cur = cur->next;
    }
    return(NULL);
}
#endif
