/** Copyright (c) 2014-present, Facebook, Inc. */

#pragma once

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "YGMacros.h"
#include "Yoga.h"

YG_EXTERN_C_BEGIN

typedef struct YGNodeList *YGNodeListRef;

YGNodeListRef YGNodeListNew(const uint32_t initialCapacity);
void YGNodeListFree(const YGNodeListRef list);
uint32_t YGNodeListCount(const YGNodeListRef list);
void YGNodeListAdd(YGNodeListRef *listp, const YGNodeRef node);
void YGNodeListInsert(YGNodeListRef *listp, const YGNodeRef node, const uint32_t index);
YGNodeRef YGNodeListRemove(const YGNodeListRef list, const uint32_t index);
YGNodeRef YGNodeListDelete(const YGNodeListRef list, const YGNodeRef node);
YGNodeRef YGNodeListGet(const YGNodeListRef list, const uint32_t index);

YG_EXTERN_C_END
