#import "YGPercentLayout.h"
#import "YGLayout+Private.h"
#import "UIView+Yoga.h"

#define YG_PROPERTY(type, lowercased_name, capitalized_name)         \
- (type)lowercased_name                                              \
{                                                                    \
return YGNodeStyleGet##capitalized_name(self.layout.node);           \
}                                                                    \
                                                                     \
- (void)set##capitalized_name:(type)lowercased_name                  \
{                                                                    \
YGNodeStyleSet##capitalized_name(self.layout.node, lowercased_name); \
}

#define YG_VALUE_PROPERTY(lowercased_name, capitalized_name)                        \
- (YGValue)lowercased_name                                                          \
{                                                                                   \
return YGNodeStyleGet##capitalized_name(self.layout.node);                          \
}                                                                                   \
                                                                                    \
- (void)set##capitalized_name:(YGValue)lowercased_name                              \
{                                                                                   \
switch (lowercased_name.unit) {                                                     \
case YGUnitPoint:                                                                   \
YGNodeStyleSet##capitalized_name(self.layout.node, lowercased_name.value);          \
break;                                                                              \
case YGUnitPercent:                                                                 \
YGNodeStyleSet##capitalized_name##Percent(self.layout.node, lowercased_name.value); \
break;                                                                              \
default:                                                                            \
NSAssert(NO, @"Not implemented");                                                   \
}                                                                                   \
}

#define YG_EDGE_PROPERTY_GETTER(type, lowercased_name, capitalized_name, property, edge) \
- (type)lowercased_name                                                                  \
{                                                                                        \
return YGNodeStyleGet##property(self.layout.node, edge);                                 \
}

#define YG_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge) \
- (void)set##capitalized_name:(CGFloat)lowercased_name                             \
{                                                                                  \
YGNodeStyleSet##property(self.layout.node, edge, lowercased_name);                 \
}

#define YG_EDGE_PROPERTY(lowercased_name, capitalized_name, property, edge)         \
YG_EDGE_PROPERTY_GETTER(CGFloat, lowercased_name, capitalized_name, property, edge) \
YG_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge)

#define YG_VALUE_EDGE_PROPERTY_SETTER(objc_lowercased_name, objc_capitalized_name, c_name, edge) \
- (void)set##objc_capitalized_name:(YGValue)objc_lowercased_name                                 \
{                                                                                                \
switch (objc_lowercased_name.unit) {                                                             \
case YGUnitPoint:                                                                                \
YGNodeStyleSet##c_name(self.layout.node, edge, objc_lowercased_name.value);                      \
break;                                                                                           \
case YGUnitPercent:                                                                              \
YGNodeStyleSet##c_name##Percent(self.layout.node, edge, objc_lowercased_name.value);             \
break;                                                                                           \
default:                                                                                         \
NSAssert(NO, @"Not implemented");                                                                \
}                                                                                                \
}

#define YG_VALUE_EDGE_PROPERTY(lowercased_name, capitalized_name, property, edge)   \
YG_EDGE_PROPERTY_GETTER(YGValue, lowercased_name, capitalized_name, property, edge) \
YG_VALUE_EDGE_PROPERTY_SETTER(lowercased_name, capitalized_name, property, edge)

#define YG_VALUE_EDGES_PROPERTIES(lowercased_name, capitalized_name)                                                  \
YG_VALUE_EDGE_PROPERTY(lowercased_name##Left, capitalized_name##Left, capitalized_name, YGEdgeLeft)                   \
YG_VALUE_EDGE_PROPERTY(lowercased_name##Top, capitalized_name##Top, capitalized_name, YGEdgeTop)                      \
YG_VALUE_EDGE_PROPERTY(lowercased_name##Right, capitalized_name##Right, capitalized_name, YGEdgeRight)                \
YG_VALUE_EDGE_PROPERTY(lowercased_name##Bottom, capitalized_name##Bottom, capitalized_name, YGEdgeBottom)             \
YG_VALUE_EDGE_PROPERTY(lowercased_name##Start, capitalized_name##Start, capitalized_name, YGEdgeStart)                \
YG_VALUE_EDGE_PROPERTY(lowercased_name##End, capitalized_name##End, capitalized_name, YGEdgeEnd)                      \
YG_VALUE_EDGE_PROPERTY(lowercased_name##Horizontal, capitalized_name##Horizontal, capitalized_name, YGEdgeHorizontal) \
YG_VALUE_EDGE_PROPERTY(lowercased_name##Vertical, capitalized_name##Vertical, capitalized_name, YGEdgeVertical)       \
YG_VALUE_EDGE_PROPERTY(lowercased_name, capitalized_name, capitalized_name, YGEdgeAll)

YGValue YGPointValue(CGFloat value)
{
  return (YGValue) { .value = value, .unit = YGUnitPoint };
}

YGValue YGPercentValue(CGFloat value)
{
  return (YGValue) { .value = value, .unit = YGUnitPercent };
}

@implementation YGPercentLayout

- (instancetype)initWithLayout:(YGLayout*)layout
{
  if (self = [super init]) {
    _layout = layout;
  }
  return self;
}

YG_VALUE_EDGE_PROPERTY(left, Left, Position, YGEdgeLeft)
YG_VALUE_EDGE_PROPERTY(top, Top, Position, YGEdgeTop)
YG_VALUE_EDGE_PROPERTY(right, Right, Position, YGEdgeRight)
YG_VALUE_EDGE_PROPERTY(bottom, Bottom, Position, YGEdgeBottom)
YG_VALUE_EDGE_PROPERTY(start, Start, Position, YGEdgeStart)
YG_VALUE_EDGE_PROPERTY(end, End, Position, YGEdgeEnd)
YG_VALUE_EDGES_PROPERTIES(margin, Margin)
YG_VALUE_EDGES_PROPERTIES(padding, Padding)

YG_VALUE_PROPERTY(width, Width)
YG_VALUE_PROPERTY(height, Height)
YG_VALUE_PROPERTY(minWidth, MinWidth)
YG_VALUE_PROPERTY(minHeight, MinHeight)
YG_VALUE_PROPERTY(maxWidth, MaxWidth)
YG_VALUE_PROPERTY(maxHeight, MaxHeight)

@end
