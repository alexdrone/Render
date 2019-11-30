/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#pragma once

#ifdef __cplusplus
#define YG_EXTERN_C_BEGIN extern "C" {
#define YG_EXTERN_C_END }
#else
#define YG_EXTERN_C_BEGIN
#define YG_EXTERN_C_END
#endif

#ifdef _WINDLL
#define WIN_EXPORT __declspec(dllexport)
#else
#define WIN_EXPORT
#endif

#ifdef WINARMDLL
#define WIN_STRUCT(type) type *
#define WIN_STRUCT_REF(value) &value
#else
#define WIN_STRUCT(type) type
#define WIN_STRUCT_REF(value) value
#endif

#ifndef FB_ASSERTIONS_ENABLED
#define FB_ASSERTIONS_ENABLED 1
#endif

#ifdef NS_ENUM
// Cannot use NSInteger as NSInteger has a different size than int (which is the default type of a
// enum).
// Therefor when linking the Yoga C library into obj-c the header is a missmatch for the Yoga ABI.
#define YG_ENUM_BEGIN(name) NS_ENUM(int, name)
#define YG_ENUM_END(name)
#else
#define YG_ENUM_BEGIN(name) enum name
#define YG_ENUM_END(name) name
#endif

#pragma once

YG_EXTERN_C_BEGIN

#define YGAlignCount 8
typedef YG_ENUM_BEGIN(YGAlign){
    YGAlignAuto,    YGAlignFlexStart, YGAlignCenter,       YGAlignFlexEnd,
    YGAlignStretch, YGAlignBaseline,  YGAlignSpaceBetween, YGAlignSpaceAround,
} YG_ENUM_END(YGAlign);
WIN_EXPORT const char *YGAlignToString(const YGAlign value);

#define YGDimensionCount 2
typedef YG_ENUM_BEGIN(YGDimension){
    YGDimensionWidth,
    YGDimensionHeight,
} YG_ENUM_END(YGDimension);
WIN_EXPORT const char *YGDimensionToString(const YGDimension value);

#define YGDirectionCount 3
typedef YG_ENUM_BEGIN(YGDirection){
    YGDirectionInherit,
    YGDirectionLTR,
    YGDirectionRTL,
} YG_ENUM_END(YGDirection);
WIN_EXPORT const char *YGDirectionToString(const YGDirection value);

#define YGDisplayCount 2
typedef YG_ENUM_BEGIN(YGDisplay){
    YGDisplayFlex,
    YGDisplayNone,
} YG_ENUM_END(YGDisplay);
WIN_EXPORT const char *YGDisplayToString(const YGDisplay value);

#define YGEdgeCount 9
typedef YG_ENUM_BEGIN(YGEdge){
    YGEdgeLeft, YGEdgeTop,        YGEdgeRight,    YGEdgeBottom, YGEdgeStart,
    YGEdgeEnd,  YGEdgeHorizontal, YGEdgeVertical, YGEdgeAll,
} YG_ENUM_END(YGEdge);
WIN_EXPORT const char *YGEdgeToString(const YGEdge value);

#define YGExperimentalFeatureCount 1
typedef YG_ENUM_BEGIN(YGExperimentalFeature){
    YGExperimentalFeatureWebFlexBasis,
} YG_ENUM_END(YGExperimentalFeature);
WIN_EXPORT const char *YGExperimentalFeatureToString(const YGExperimentalFeature value);

#define YGFlexDirectionCount 4
typedef YG_ENUM_BEGIN(YGFlexDirection){
    YGFlexDirectionColumn,
    YGFlexDirectionColumnReverse,
    YGFlexDirectionRow,
    YGFlexDirectionRowReverse,
} YG_ENUM_END(YGFlexDirection);
WIN_EXPORT const char *YGFlexDirectionToString(const YGFlexDirection value);

#define YGJustifyCount 5
typedef YG_ENUM_BEGIN(YGJustify){
    YGJustifyFlexStart,    YGJustifyCenter,      YGJustifyFlexEnd,
    YGJustifySpaceBetween, YGJustifySpaceAround,
} YG_ENUM_END(YGJustify);
WIN_EXPORT const char *YGJustifyToString(const YGJustify value);

#define YGLogLevelCount 6
typedef YG_ENUM_BEGIN(YGLogLevel){
    YGLogLevelError, YGLogLevelWarn,    YGLogLevelInfo,
    YGLogLevelDebug, YGLogLevelVerbose, YGLogLevelFatal,
} YG_ENUM_END(YGLogLevel);
WIN_EXPORT const char *YGLogLevelToString(const YGLogLevel value);

#define YGMeasureModeCount 3
typedef YG_ENUM_BEGIN(YGMeasureMode){
    YGMeasureModeUndefined,
    YGMeasureModeExactly,
    YGMeasureModeAtMost,
} YG_ENUM_END(YGMeasureMode);
WIN_EXPORT const char *YGMeasureModeToString(const YGMeasureMode value);

#define YGNodeTypeCount 2
typedef YG_ENUM_BEGIN(YGNodeType){
    YGNodeTypeDefault,
    YGNodeTypeText,
} YG_ENUM_END(YGNodeType);
WIN_EXPORT const char *YGNodeTypeToString(const YGNodeType value);

#define YGOverflowCount 3
typedef YG_ENUM_BEGIN(YGOverflow){
    YGOverflowVisible,
    YGOverflowHidden,
    YGOverflowScroll,
} YG_ENUM_END(YGOverflow);
WIN_EXPORT const char *YGOverflowToString(const YGOverflow value);

#define YGPositionTypeCount 2
typedef YG_ENUM_BEGIN(YGPositionType){
    YGPositionTypeRelative,
    YGPositionTypeAbsolute,
} YG_ENUM_END(YGPositionType);
WIN_EXPORT const char *YGPositionTypeToString(const YGPositionType value);

#define YGPrintOptionsCount 3
typedef YG_ENUM_BEGIN(YGPrintOptions){
    YGPrintOptionsLayout = 1,
    YGPrintOptionsStyle = 2,
    YGPrintOptionsChildren = 4,
} YG_ENUM_END(YGPrintOptions);
WIN_EXPORT const char *YGPrintOptionsToString(const YGPrintOptions value);

#define YGUnitCount 4
typedef YG_ENUM_BEGIN(YGUnit){
    YGUnitUndefined,
    YGUnitPoint,
    YGUnitPercent,
    YGUnitAuto,
} YG_ENUM_END(YGUnit);
WIN_EXPORT const char *YGUnitToString(const YGUnit value);

#define YGWrapCount 3
typedef YG_ENUM_BEGIN(YGWrap){
    YGWrapNoWrap,
    YGWrapWrap,
    YGWrapWrapReverse,
} YG_ENUM_END(YGWrap);
WIN_EXPORT const char *YGWrapToString(const YGWrap value);

YG_EXTERN_C_END

#pragma once

#include <assert.h>
#include <math.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef __cplusplus
#include <stdbool.h>
#endif

// Not defined in MSVC++
#ifndef NAN
static const unsigned long __nan[2] = {0xffffffff, 0x7fffffff};
#define NAN (*(const float *)__nan)
#endif

#define YGUndefined NAN

YG_EXTERN_C_BEGIN

typedef struct YGSize {
  float width;
  float height;
} YGSize;

typedef struct YGValue {
  float value;
  YGUnit unit;
} YGValue;

typedef struct __attribute__((objc_boxable)) YGValue YGValue;

static const YGValue YGValueUndefined = {YGUndefined, YGUnitUndefined};
static const YGValue YGValueAuto = {YGUndefined, YGUnitAuto};

typedef struct YGConfig *YGConfigRef;
typedef struct YGNode *YGNodeRef;
typedef YGSize (*YGMeasureFunc)(YGNodeRef node, float width, YGMeasureMode widthMode, float height,
                                YGMeasureMode heightMode);
typedef float (*YGBaselineFunc)(YGNodeRef node, const float width, const float height);
typedef void (*YGPrintFunc)(YGNodeRef node);
typedef int (*YGLogger)(const YGConfigRef config, const YGNodeRef node, YGLogLevel level,
                        const char *format, va_list args);
typedef void (*YGNodeClonedFunc)(YGNodeRef oldNode, YGNodeRef newNode, YGNodeRef parent,
                                 int childIndex);

typedef void *(*YGMalloc)(size_t size);
typedef void *(*YGCalloc)(size_t count, size_t size);
typedef void *(*YGRealloc)(void *ptr, size_t size);
typedef void (*YGFree)(void *ptr);

// YGNode
WIN_EXPORT YGNodeRef YGNodeNew(void);
WIN_EXPORT YGNodeRef YGNodeNewWithConfig(const YGConfigRef config);
WIN_EXPORT YGNodeRef YGNodeClone(const YGNodeRef node);
WIN_EXPORT void YGNodeFree(const YGNodeRef node);
WIN_EXPORT void YGNodeFreeRecursive(const YGNodeRef node);
WIN_EXPORT void YGNodeReset(const YGNodeRef node);
WIN_EXPORT int32_t YGNodeGetInstanceCount(void);

WIN_EXPORT void YGNodeInsertChild(const YGNodeRef node, const YGNodeRef child,
                                  const uint32_t index);
WIN_EXPORT void YGNodeRemoveChild(const YGNodeRef node, const YGNodeRef child);
WIN_EXPORT void YGNodeRemoveAllChildren(const YGNodeRef node);
WIN_EXPORT YGNodeRef YGNodeGetChild(const YGNodeRef node, const uint32_t index);
WIN_EXPORT YGNodeRef YGNodeGetParent(const YGNodeRef node);
WIN_EXPORT uint32_t YGNodeGetChildCount(const YGNodeRef node);

WIN_EXPORT void YGNodeCalculateLayout(const YGNodeRef node, const float availableWidth,
                                      const float availableHeight,
                                      const YGDirection parentDirection);

// Mark a node as dirty. Only valid for nodes with a custom measure function
// set.
// YG knows when to mark all other nodes as dirty but because nodes with
// measure functions
// depends on information not known to YG they must perform this dirty
// marking manually.
WIN_EXPORT void YGNodeMarkDirty(const YGNodeRef node);
WIN_EXPORT bool YGNodeIsDirty(const YGNodeRef node);

WIN_EXPORT void YGNodePrint(const YGNodeRef node, const YGPrintOptions options);

WIN_EXPORT bool YGFloatIsUndefined(const float value);

WIN_EXPORT bool YGNodeCanUseCachedMeasurement(const YGMeasureMode widthMode, const float width,
                                              const YGMeasureMode heightMode, const float height,
                                              const YGMeasureMode lastWidthMode,
                                              const float lastWidth,
                                              const YGMeasureMode lastHeightMode,
                                              const float lastHeight, const float lastComputedWidth,
                                              const float lastComputedHeight, const float marginRow,
                                              const float marginColumn, const YGConfigRef config);

WIN_EXPORT void YGNodeCopyStyle(const YGNodeRef dstNode, const YGNodeRef srcNode);

#define YG_NODE_PROPERTY(type, name, paramName)                          \
  WIN_EXPORT void YGNodeSet##name(const YGNodeRef node, type paramName); \
  WIN_EXPORT type YGNodeGet##name(const YGNodeRef node);

#define YG_NODE_STYLE_PROPERTY(type, name, paramName)                               \
  WIN_EXPORT void YGNodeStyleSet##name(const YGNodeRef node, const type paramName); \
  WIN_EXPORT type YGNodeStyleGet##name(const YGNodeRef node);

#define YG_NODE_STYLE_PROPERTY_UNIT(type, name, paramName)                                    \
  WIN_EXPORT void YGNodeStyleSet##name(const YGNodeRef node, const float paramName);          \
  WIN_EXPORT void YGNodeStyleSet##name##Percent(const YGNodeRef node, const float paramName); \
  WIN_EXPORT type YGNodeStyleGet##name(const YGNodeRef node);

#define YG_NODE_STYLE_PROPERTY_UNIT_AUTO(type, name, paramName) \
  YG_NODE_STYLE_PROPERTY_UNIT(type, name, paramName)            \
  WIN_EXPORT void YGNodeStyleSet##name##Auto(const YGNodeRef node);

#define YG_NODE_STYLE_EDGE_PROPERTY(type, name, paramName)                      \
  WIN_EXPORT void YGNodeStyleSet##name(const YGNodeRef node, const YGEdge edge, \
                                       const type paramName);                   \
  WIN_EXPORT type YGNodeStyleGet##name(const YGNodeRef node, const YGEdge edge);

#define YG_NODE_STYLE_EDGE_PROPERTY_UNIT(type, name, paramName)                          \
  WIN_EXPORT void YGNodeStyleSet##name(const YGNodeRef node, const YGEdge edge,          \
                                       const float paramName);                           \
  WIN_EXPORT void YGNodeStyleSet##name##Percent(const YGNodeRef node, const YGEdge edge, \
                                                const float paramName);                  \
  WIN_EXPORT WIN_STRUCT(type) YGNodeStyleGet##name(const YGNodeRef node, const YGEdge edge);

#define YG_NODE_STYLE_EDGE_PROPERTY_UNIT_AUTO(type, name) \
  WIN_EXPORT void YGNodeStyleSet##name##Auto(const YGNodeRef node, const YGEdge edge);

#define YG_NODE_LAYOUT_PROPERTY(type, name) \
  WIN_EXPORT type YGNodeLayoutGet##name(const YGNodeRef node);

#define YG_NODE_LAYOUT_EDGE_PROPERTY(type, name) \
  WIN_EXPORT type YGNodeLayoutGet##name(const YGNodeRef node, const YGEdge edge);

YG_NODE_PROPERTY(void *, Context, context);
YG_NODE_PROPERTY(YGMeasureFunc, MeasureFunc, measureFunc);
YG_NODE_PROPERTY(YGBaselineFunc, BaselineFunc, baselineFunc)
YG_NODE_PROPERTY(YGPrintFunc, PrintFunc, printFunc);
YG_NODE_PROPERTY(bool, HasNewLayout, hasNewLayout);
YG_NODE_PROPERTY(YGNodeType, NodeType, nodeType);

YG_NODE_STYLE_PROPERTY(YGDirection, Direction, direction);
YG_NODE_STYLE_PROPERTY(YGFlexDirection, FlexDirection, flexDirection);
YG_NODE_STYLE_PROPERTY(YGJustify, JustifyContent, justifyContent);
YG_NODE_STYLE_PROPERTY(YGAlign, AlignContent, alignContent);
YG_NODE_STYLE_PROPERTY(YGAlign, AlignItems, alignItems);
YG_NODE_STYLE_PROPERTY(YGAlign, AlignSelf, alignSelf);
YG_NODE_STYLE_PROPERTY(YGPositionType, PositionType, positionType);
YG_NODE_STYLE_PROPERTY(YGWrap, FlexWrap, flexWrap);
YG_NODE_STYLE_PROPERTY(YGOverflow, Overflow, overflow);
YG_NODE_STYLE_PROPERTY(YGDisplay, Display, display);

YG_NODE_STYLE_PROPERTY(float, Flex, flex);
YG_NODE_STYLE_PROPERTY(float, FlexGrow, flexGrow);
YG_NODE_STYLE_PROPERTY(float, FlexShrink, flexShrink);
YG_NODE_STYLE_PROPERTY_UNIT_AUTO(YGValue, FlexBasis, flexBasis);

YG_NODE_STYLE_EDGE_PROPERTY_UNIT(YGValue, Position, position);
YG_NODE_STYLE_EDGE_PROPERTY_UNIT(YGValue, Margin, margin);
YG_NODE_STYLE_EDGE_PROPERTY_UNIT_AUTO(YGValue, Margin);
YG_NODE_STYLE_EDGE_PROPERTY_UNIT(YGValue, Padding, padding);
YG_NODE_STYLE_EDGE_PROPERTY(float, Border, border);

YG_NODE_STYLE_PROPERTY_UNIT_AUTO(YGValue, Width, width);
YG_NODE_STYLE_PROPERTY_UNIT_AUTO(YGValue, Height, height);
YG_NODE_STYLE_PROPERTY_UNIT(YGValue, MinWidth, minWidth);
YG_NODE_STYLE_PROPERTY_UNIT(YGValue, MinHeight, minHeight);
YG_NODE_STYLE_PROPERTY_UNIT(YGValue, MaxWidth, maxWidth);
YG_NODE_STYLE_PROPERTY_UNIT(YGValue, MaxHeight, maxHeight);

// Yoga specific properties, not compatible with flexbox specification
// Aspect ratio control the size of the undefined dimension of a node.
// Aspect ratio is encoded as a floating point value width/height. e.g. A value of 2 leads to a node
// with a width twice the size of its height while a value of 0.5 gives the opposite effect.
//
// - On a node with a set width/height aspect ratio control the size of the unset dimension
// - On a node with a set flex basis aspect ratio controls the size of the node in the cross axis if
// unset
// - On a node with a measure function aspect ratio works as though the measure function measures
// the flex basis
// - On a node with flex grow/shrink aspect ratio controls the size of the node in the cross axis if
// unset
// - Aspect ratio takes min/max dimensions into account
YG_NODE_STYLE_PROPERTY(float, AspectRatio, aspectRatio);

YG_NODE_LAYOUT_PROPERTY(float, Left);
YG_NODE_LAYOUT_PROPERTY(float, Top);
YG_NODE_LAYOUT_PROPERTY(float, Right);
YG_NODE_LAYOUT_PROPERTY(float, Bottom);
YG_NODE_LAYOUT_PROPERTY(float, Width);
YG_NODE_LAYOUT_PROPERTY(float, Height);
YG_NODE_LAYOUT_PROPERTY(YGDirection, Direction);
YG_NODE_LAYOUT_PROPERTY(bool, HadOverflow);

// Get the computed values for these nodes after performing layout. If they were set using
// point values then the returned value will be the same as YGNodeStyleGetXXX. However if
// they were set using a percentage value then the returned value is the computed value used
// during layout.
YG_NODE_LAYOUT_EDGE_PROPERTY(float, Margin);
YG_NODE_LAYOUT_EDGE_PROPERTY(float, Border);
YG_NODE_LAYOUT_EDGE_PROPERTY(float, Padding);

WIN_EXPORT void YGConfigSetLogger(const YGConfigRef config, YGLogger logger);
WIN_EXPORT void YGLog(const YGNodeRef node, YGLogLevel level, const char *message, ...);
WIN_EXPORT void YGLogWithConfig(const YGConfigRef config, YGLogLevel level, const char *format,
                                ...);
WIN_EXPORT void YGAssert(const bool condition, const char *message);
WIN_EXPORT void YGAssertWithNode(const YGNodeRef node, const bool condition, const char *message);
WIN_EXPORT void YGAssertWithConfig(const YGConfigRef config, const bool condition,
                                   const char *message);

// Set this to number of pixels in 1 point to round calculation results
// If you want to avoid rounding - set PointScaleFactor to 0
WIN_EXPORT void YGConfigSetPointScaleFactor(const YGConfigRef config, const float pixelsInPoint);

// Yoga previously had an error where containers would take the maximum space possible instead of
// the minimum
// like they are supposed to. In practice this resulted in implicit behaviour similar to align-self:
// stretch;
// Because this was such a long-standing bug we must allow legacy users to switch back to this
// behaviour.
WIN_EXPORT void YGConfigSetUseLegacyStretchBehaviour(const YGConfigRef config,
                                                     const bool useLegacyStretchBehaviour);

// YGConfig
WIN_EXPORT YGConfigRef YGConfigNew(void);
WIN_EXPORT void YGConfigFree(const YGConfigRef config);
WIN_EXPORT void YGConfigCopy(const YGConfigRef dest, const YGConfigRef src);
WIN_EXPORT int32_t YGConfigGetInstanceCount(void);

WIN_EXPORT void YGConfigSetExperimentalFeatureEnabled(const YGConfigRef config,
                                                      const YGExperimentalFeature feature,
                                                      const bool enabled);
WIN_EXPORT bool YGConfigIsExperimentalFeatureEnabled(const YGConfigRef config,
                                                     const YGExperimentalFeature feature);

// Using the web defaults is the prefered configuration for new projects.
// Usage of non web defaults should be considered as legacy.
WIN_EXPORT void YGConfigSetUseWebDefaults(const YGConfigRef config, const bool enabled);
WIN_EXPORT bool YGConfigGetUseWebDefaults(const YGConfigRef config);

WIN_EXPORT void YGConfigSetNodeClonedFunc(const YGConfigRef config,
                                          const YGNodeClonedFunc callback);

// Export only for C#
WIN_EXPORT YGConfigRef YGConfigGetDefault(void);

WIN_EXPORT void YGConfigSetContext(const YGConfigRef config, void *context);
WIN_EXPORT void *YGConfigGetContext(const YGConfigRef config);

WIN_EXPORT void YGSetMemoryFuncs(YGMalloc ygmalloc, YGCalloc yccalloc, YGRealloc ygrealloc,
                                 YGFree ygfree);

WIN_EXPORT float YGRoundValueToPixelGrid(const float value, const float pointScaleFactor,
                                         const bool forceCeil, const bool forceFloor);

YG_EXTERN_C_END

#pragma once

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "Yoga.h"

YG_EXTERN_C_BEGIN

typedef struct YGNodeList *YGNodeListRef;

YGNodeListRef YGNodeListNew(const uint32_t initialCapacity);
void YGNodeListFree(const YGNodeListRef list);
uint32_t YGNodeListCount(const YGNodeListRef list);
void YGNodeListAdd(YGNodeListRef *listp, const YGNodeRef node);
void YGNodeListInsert(YGNodeListRef *listp, const YGNodeRef node, const uint32_t index);
void YGNodeListReplace(const YGNodeListRef list, const uint32_t index, const YGNodeRef newNode);
void YGNodeListRemoveAll(const YGNodeListRef list);
YGNodeRef YGNodeListRemove(const YGNodeListRef list, const uint32_t index);
YGNodeRef YGNodeListDelete(const YGNodeListRef list, const YGNodeRef node);
YGNodeRef YGNodeListGet(const YGNodeListRef list, const uint32_t index);
YGNodeListRef YGNodeListClone(YGNodeListRef list);

YG_EXTERN_C_END
