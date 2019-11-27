#ifndef CRInternalMacros_h
#define CRInternalMacros_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - Type inference and dynamic casts

// Type inference for local variables.
#if defined(__cplusplus)
#else
#define auto __auto_type
#endif

// Equivalent to swift nil coalescing operator '??'.
#if defined(__cplusplus)
template <typename T>
static inline T *_Nonnull CRNilCoalescing(T *_Nullable value, T *_Nonnull defaultValue) {
  return value != nil ? value : defaultValue;
}
#define CR_NIL_COALESCING(VALUE, DEFAULT) CRNilCoalescing(VALUE, DEFAULT)
#else
#define CR_NIL_COALESCING(VALUE, DEFAULT) (VALUE != nil ? VALUE : DEFAULT)
#endif

/// Mirrors Swift's 'as?' operator.
#if defined(__cplusplus)
template <typename T>
static inline T *_Nullable CRDynamicCast(__unsafe_unretained id _Nullable obj,
                                         bool assert = false) {
  if ([(id)obj isKindOfClass:[T class]]) {
    return obj;
  }
  return nil;
}
template <typename T>
static inline T *_Nonnull CRDynamicCastOrAssert(__unsafe_unretained id _Nullable obj) {
  return (T * _Nonnull) CRDynamicCast<T>(obj, true);
}
#define CR_DYNAMIC_CAST(TYPE, VALUE) CRDynamicCast<TYPE>(VALUE)
#define CR_DYNAMIC_CAST_OR_ASSERT(TYPE, VALUE) CRDynamicCastOrAssert<TYPE>(VALUE)
#else
static inline id CRDynamicCast(__unsafe_unretained id obj, Class type, BOOL assert) {
  if ([(id)obj isKindOfClass:type]) {
    return obj;
  }
  if (assert) {
    NSCAssert(NO, @"failed to cast %@ to %@", obj, type);
  }
  return nil;
}
#define CR_DYNAMIC_CAST(TYPE, VALUE) ((TYPE * _Nullable) CRDynamicCast(VALUE, TYPE.class, NO))
#define CR_DYNAMIC_CAST_OR_ASSERT(TYPE, VALUE) \
  ((TYPE * _Nonnull) CRDynamicCast(VALUE, TYPE.class, true))
#endif

#pragma mark - Weakify

#define CR_WEAKNAME_(VAR) VAR##_weak_

#define CR_WEAKIFY(VAR) __weak __typeof__(VAR) CR_WEAKNAME_(VAR) = (VAR)

#define CR_STRONGIFY(VAR)                                                           \
  _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wshadow\"") \
      __strong __typeof__(VAR) VAR = CR_WEAKNAME_(VAR);                             \
  _Pragma("clang diagnostic pop")

#define CR_STRONGIFY_AND_RETURN_IF_NIL(VAR) \
  CR_STRONGIFY(VAR);                        \
  if (!(VAR)) {                             \
    return;                                 \
  }

// Safe keypath litterals.
#define CR_UNSAFE_KEYPATH(p) @ #p

#if DEBUG
#define CR_KEYPATH(o, p) ((void)(NO && ((void)o.p, NO)), @ #p)
#else
#define CR_KEYPATH(o, p) @ #p
#endif

#pragma mark - Misc

// Equivalent to Swift's @noescape.
#define CR_NOESCAPE __attribute__((noescape))

// Ensure the caller method is being invoked on the main thread.
#define CR_ASSERT_ON_MAIN_THREAD() NSAssert(NSThread.isMainThread, @"called off the main thread.")

#pragma mark - Geometry

#define CR_CLAMP(x, low, high)                           \
  ({                                                     \
    __typeof__(x) __x = (x);                             \
    __typeof__(low) __low = (low);                       \
    __typeof__(high) __high = (high);                    \
    __x > __high ? __high : (__x < __low ? __low : __x); \
  })

#define CR_CGFLOAT_MAX 32768
#define CR_CGFLOAT_UNDEFINED YGUndefined
#define CR_CGFLOAT_FLEXIBLE CR_CGFLOAT_MAX
#define CR_NORMALIZE(value) (value >= 0.0 && value <= CR_CGFLOAT_MAX ? value : 0.0)

#pragma mark - Boxable structs

// Ensure the struct can be boxed in a NSValue by using the @ symbol.
#define CR_OBJC_BOXABLE __attribute__((objc_boxable))

typedef struct CR_OBJC_BOXABLE CGPoint CGPoint;
typedef struct CR_OBJC_BOXABLE CGSize CGSize;
typedef struct CR_OBJC_BOXABLE CGRect CGRect;
typedef struct CR_OBJC_BOXABLE CGVector CGVector;
typedef struct CR_OBJC_BOXABLE UIEdgeInsets UIEdgeInsets;
typedef struct CR_OBJC_BOXABLE _NSRange NSRange;
typedef struct CR_OBJC_BOXABLE CGAffineTransform CGAffineTransform;

#pragma mark - Generics

NS_ASSUME_NONNULL_BEGIN

@protocol CRFastEnumeration <NSFastEnumeration>
- (id)CR_enumeratedType;
@end

// Usage: CR_FOREACH (s, strings) { ... }
// For each loops using type inference.
#define CR_FOREACH(element, collection) \
  for (typeof((collection).CR_enumeratedType) element in (collection))

@interface NSArray <ElementType>(CRFastEnumeration) <CRFastEnumeration>
- (ElementType)CR_enumeratedType;
@end

@interface NSSet <ElementType>(CRFastEnumeration) <CRFastEnumeration>
- (ElementType)CR_enumeratedType;
@end

@interface NSDictionary <KeyType, ValueType>(CRFastEnumeration) <CRFastEnumeration>
- (KeyType)CR_enumeratedType;
@end

/// This overrides the NSObject declaration of copy with specialized ones that retain
// the generic type.
// This is pure compiler sugar and will create additional warnings for type mismatches.
// @note id-casted objects will create a warning when copy is called on them as there are multiple
// declarations available. Either cast to specific type or to NSObject to work around this.
@interface NSArray <ElementType>(CRSafeCopy)
// Same as `copy` but retains the generic type.
- (NSArray<ElementType> *)copy;
// Same as `mutableCopy` but retains the generic type.
- (NSMutableArray<ElementType> *)mutableCopy;
@end

@interface NSSet <ElementType>(CRSafeCopy)
// Same as `copy` but retains the generic type.
- (NSSet<ElementType> *)copy;
// Same as `mutableCopy` but retains the generic type.
- (NSMutableSet<ElementType> *)mutableCopy;
@end

@interface NSDictionary <KeyType, ValueType>(CRSafeCopy)
// Same as `copy` but retains the generic type.
- (NSDictionary<KeyType, ValueType> *)copy;
// Same as `mutableCopy` but retains the generic type.
- (NSMutableDictionary<KeyType, ValueType> *)mutableCopy;
@end

@interface NSOrderedSet <ElementType>(CRSafeCopy)
// Same as `copy` but retains the generic type.
- (NSOrderedSet<ElementType> *)copy;
// Same as `mutableCopy` but retains the generic type.
- (NSMutableOrderedSet<ElementType> *)mutableCopy;
@end

@interface NSHashTable <ElementType>(CRSafeCopy)
// Same as `copy` but retains the generic type.
- (NSHashTable<ElementType> *)copy;
@end

@interface NSMapTable <KeyType, ValueType>(CRSafeCopy)
// Same as `copy` but retains the generic type.
- (NSMapTable<KeyType, ValueType> *)copy;
@end

NS_ASSUME_NONNULL_END

#pragma mark - NSArray to std::vector and viceversa

#if defined(__cplusplus)
#include <vector>

NS_ASSUME_NONNULL_BEGIN

template <typename T>
static inline NSArray *CRArrayWithVector(const std::vector<T> &vector,
                                         id (^block)(const T &value)) {
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:vector.size()];
  for (const T &value : vector) {
    [result addObject:block(value)];
  }

  return result;
}

template <typename T>
static inline std::vector<T> CRVectorWithElements(id<NSFastEnumeration> array,
                                                  T (^_Nullable block)(id value)) {
  std::vector<T> result;
  for (id value in array) {
    result.push_back(block(value));
  }
  return result;
}

NS_ASSUME_NONNULL_END

#endif

#pragma mark - Logging

#define CR_NOT_REACHED() CR_LOG(@"Unexpected exec @ %s:%s ", __FILE__, __LINE__)

#define CR_LOG_ENABLED 1

#ifdef CR_LOG_ENABLED
#define CR_LOG(fmt, ...) NSLog([NSString stringWithFormat:@"(client) %@", fmt], ##__VA_ARGS__)
#else
#define CR_LOG(...)
#endif

#endif /* CRMaCRos_h */
