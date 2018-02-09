// Generated by Apple Swift version 3.1 (swiftlang-802.0.53 clang-802.0.42)
#pragma clang diagnostic push

#if defined(__has_include) && __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if defined(__has_include) && __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if defined(__has_attribute) && __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if defined(__has_attribute) && __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if defined(__has_attribute) && __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if defined(__has_attribute) && __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_EXTRA _name : _type
# if defined(__has_feature) && __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if defined(__has_feature) && __has_feature(modules)
@import ObjectiveC;
@import UIKit;
@import CoreGraphics;
@import Foundation;
@import CoreFoundation;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
@class UICollectionViewLayout;
@class UICollectionView;
@class UICollectionViewCell;

/// Wraps a UICollectionView in a node definition.
/// CollectionNode.children will be wrapped into UICollectionView.
/// Consider using TableNode over Node<ScrollView> where you have a big number of items to be
/// displayed.
SWIFT_CLASS("_TtC6Render14CollectionNode")
@interface CollectionNode : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic) BOOL disableCellReuse;
@property (nonatomic) BOOL shouldUseDiff;
@property (nonatomic) NSInteger maximumNuberOfDiffUpdates;
/// This component is the n-th children.
@property (nonatomic) NSInteger index;
@property (nonatomic, readonly, copy) NSString * _Nonnull debugType;
+ (UICollectionViewLayout * _Nonnull)defaultCollectionViewLayout SWIFT_WARN_UNUSED_RESULT;
- (void)layoutIn:(CGSize)bounds;
/// Re-applies the configuration closures to the UITableView and reload the data source.
- (void)configureIn:(CGSize)bounds;
/// Tells the data source to return the number of rows in a given section of a collection view.
- (NSInteger)collectionView:(UICollectionView * _Nonnull)collectionView numberOfItemsInSection:(NSInteger)section SWIFT_WARN_UNUSED_RESULT;
- (CGSize)collectionView:(UICollectionView * _Nonnull)collectionView layout:(UICollectionViewLayout * _Nonnull)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath * _Nonnull)indexPath SWIFT_WARN_UNUSED_RESULT;
/// Asks the data source for a cell to insert in a particular location of the collection view.
- (UICollectionViewCell * _Nonnull)collectionView:(UICollectionView * _Nonnull)collectionView cellForItemAtIndexPath:(NSIndexPath * _Nonnull)indexPath SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end

@class UIView;
@class NSCoder;

/// Wraps a component in a UICollectionViewCell.
SWIFT_CLASS("_TtC6Render35InternalComponentCollectionViewCell")
@interface InternalComponentCollectionViewCell : UICollectionViewCell
@property (nonatomic, weak) UIView * _Nullable listView;
@property (nonatomic, copy) NSIndexPath * _Nonnull currentIndexPath;
- (CGSize)sizeThatFits:(CGSize)size SWIFT_WARN_UNUSED_RESULT;
@property (nonatomic, readonly) CGSize intrinsicContentSize;
- (nonnull instancetype)initWithFrame:(CGRect)frame OBJC_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder * _Nonnull)aDecoder OBJC_DESIGNATED_INITIALIZER;
@end


/// Wraps a component in a UITableViewCell.
SWIFT_CLASS("_TtC6Render30InternalComponentTableViewCell")
@interface InternalComponentTableViewCell : UITableViewCell
@property (nonatomic, weak) UIView * _Nullable listView;
@property (nonatomic, copy) NSIndexPath * _Nonnull currentIndexPath;
- (nonnull instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString * _Nullable)reuseIdentifier OBJC_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder * _Nonnull)aDecoder OBJC_DESIGNATED_INITIALIZER;
- (CGSize)sizeThatFits:(CGSize)size SWIFT_WARN_UNUSED_RESULT;
@property (nonatomic, readonly) CGSize intrinsicContentSize;
@end

@class UITableView;

/// Wraps a UITableView in a node definition.
/// TableNode.children will be wrapped into UITableViewCell.
/// Consider using TableNode over Node<ScrollView> where you have a big number of items to be
/// displayed.
SWIFT_CLASS("_TtC6Render9TableNode")
@interface TableNode : NSObject <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) BOOL disableCellReuse;
@property (nonatomic) BOOL shouldUseDiff;
@property (nonatomic) NSInteger maximumNuberOfDiffUpdates;
/// This component is the n-th children.
@property (nonatomic) NSInteger index;
@property (nonatomic, readonly, copy) NSString * _Nonnull debugType;
- (void)layoutIn:(CGSize)bounds;
/// Re-applies the configuration closures to the UITableView and reload the data source.
- (void)configureIn:(CGSize)bounds;
/// Tells the data source to return the number of rows in a given section of a table view.
- (NSInteger)tableView:(UITableView * _Nonnull)tableView numberOfRowsInSection:(NSInteger)section SWIFT_WARN_UNUSED_RESULT;
/// Asks the data source for a cell to insert in a particular location of the table view.
- (UITableViewCell * _Nonnull)tableView:(UITableView * _Nonnull)tableView cellForRowAtIndexPath:(NSIndexPath * _Nonnull)indexPath SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
@end


@interface UIButton (SWIFT_EXTENSION(Render))
@end


@interface UICollectionView (SWIFT_EXTENSION(Render))
/// Refreshes the component at the given index path.
- (void)updateAt:(NSIndexPath * _Nonnull)indexPath;
/// Re-renders all the compoents currently visible on screen.
/// Call this method whenever the collecrion view changes its bounds/size.
- (void)updateVisibleComponents;
@end


@interface UIControl (SWIFT_EXTENSION(Render))
- (void)onEvent:(UIControlEvents)event :(void (^ _Nonnull)(void))closure;
@end


@interface UIGestureRecognizer (SWIFT_EXTENSION(Render))
@end


@interface UIImageView (SWIFT_EXTENSION(Render))
@end


@interface UILabel (SWIFT_EXTENSION(Render))
@end


@interface UILongPressGestureRecognizer (SWIFT_EXTENSION(Render))
- (nonnull instancetype)initWithHandler:(void (^ _Nonnull)(UILongPressGestureRecognizer * _Nonnull))handler;
@end


@interface UIPanGestureRecognizer (SWIFT_EXTENSION(Render))
- (nonnull instancetype)initWithHandler:(void (^ _Nonnull)(UIPanGestureRecognizer * _Nonnull))handler;
@end


@interface UIPinchGestureRecognizer (SWIFT_EXTENSION(Render))
- (nonnull instancetype)initWithHandler:(void (^ _Nonnull)(UIPinchGestureRecognizer * _Nonnull))handler;
@end


@interface UIRotationGestureRecognizer (SWIFT_EXTENSION(Render))
- (nonnull instancetype)initWithHandler:(void (^ _Nonnull)(UIRotationGestureRecognizer * _Nonnull))handler;
@end


@interface UIScreenEdgePanGestureRecognizer (SWIFT_EXTENSION(Render))
- (nonnull instancetype)initWithHandler:(void (^ _Nonnull)(UIScreenEdgePanGestureRecognizer * _Nonnull))handler;
@end


@interface UIScrollView (SWIFT_EXTENSION(Render))
@end


@interface UISwipeGestureRecognizer (SWIFT_EXTENSION(Render))
- (nonnull instancetype)initWithDirection:(UISwipeGestureRecognizerDirection)direction handler:(void (^ _Nonnull)(UISwipeGestureRecognizer * _Nonnull))handler;
@end


@interface UITableView (SWIFT_EXTENSION(Render))
/// Refreshes the component at the given index path.
- (void)updateAt:(NSIndexPath * _Nonnull)indexPath;
/// Re-renders all the compoents currently visible on screen.
/// Call this method whenever the table view changes its bounds/size.
- (void)updateVisibleComponents;
@end


@interface UITapGestureRecognizer (SWIFT_EXTENSION(Render))
- (nonnull instancetype)initWithTaps:(NSInteger)taps touches:(NSInteger)touches handler:(void (^ _Nonnull)(UITapGestureRecognizer * _Nonnull))handler;
@end


@interface UITextField (SWIFT_EXTENSION(Render))
@end


@interface UITextView (SWIFT_EXTENSION(Render))
@end


@interface UIView (SWIFT_EXTENSION(Render))
@end


@interface UIView (SWIFT_EXTENSION(Render))
- (void)onTap:(void (^ _Nonnull)(UITapGestureRecognizer * _Nonnull))handler;
- (void)onDoubleTap:(void (^ _Nonnull)(UITapGestureRecognizer * _Nonnull))handler;
- (void)onLongPress:(void (^ _Nonnull)(UILongPressGestureRecognizer * _Nonnull))handler;
- (void)onSwipeLeft:(void (^ _Nonnull)(UISwipeGestureRecognizer * _Nonnull))handler;
- (void)onSwipeRight:(void (^ _Nonnull)(UISwipeGestureRecognizer * _Nonnull))handler;
- (void)onSwipeUp:(void (^ _Nonnull)(UISwipeGestureRecognizer * _Nonnull))handler;
- (void)onSwipeDown:(void (^ _Nonnull)(UISwipeGestureRecognizer * _Nonnull))handler;
- (void)onPan:(void (^ _Nonnull)(UIPanGestureRecognizer * _Nonnull))handler;
- (void)onPinch:(void (^ _Nonnull)(UIPinchGestureRecognizer * _Nonnull))handler;
- (void)onRotate:(void (^ _Nonnull)(UIRotationGestureRecognizer * _Nonnull))handler;
- (void)onScreenEdgePan:(void (^ _Nonnull)(UIScreenEdgePanGestureRecognizer * _Nonnull))handler;
@end


@interface UIView (SWIFT_EXTENSION(Render))
@property (nonatomic) BOOL isAnimatable;
@property (nonatomic) BOOL hasNode;
@property (nonatomic) BOOL isNewlyCreated;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat oldCornerRadius;
- (void)animateCornerRadiusInHierarchyIfNecessaryWithDuration:(CFTimeInterval)duration;
- (void)debugBoudingRect;
@end

#pragma clang diagnostic pop