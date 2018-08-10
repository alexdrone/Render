#ifndef CRMacros_h
#define CRMacros_h

#if defined(__cplusplus)
#else
#define auto __auto_type
#endif

#if DEBUG
#define CR_KEYPATH(o, p) ((void)(NO && ((void)o.p, NO)), @ #p)
#else
#define CR_KEYPATH(o, p) @ #p
#endif

#define CR_WEAKNAME_(VAR) VAR ## _weak_

#define CR_WEAKIFY(VAR) __weak __typeof__(VAR) CR_WEAKNAME_(VAR) = (VAR);

#define CR_STRONGIFY(VAR) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong __typeof__(VAR) VAR = CR_WEAKNAME_(VAR); \
_Pragma("clang diagnostic pop")

#define CR_STRONGIFY_AND_RETURN_IF_NIL(VAR) \
CR_STRONGIFY(VAR); \
if (!(VAR)) { \
return; \
}

#define CR_NIL_COALESCING(VALUE, DEFAULT) VALUE != nil ? VALUE : DEFAULT

#define CR_DYNAMIC_CAST(TYPE, VALUE) ([VALUE isKindOfClass:TYPE.class] ? (TYPE *)VALUE : nil)

#define CR_ASSERT_ON_MAIN_THREAD NSAssert(NSThread.isMainThread, @"%@ called off the main thread.", NSStringFromSelector(_cmd))

typedef struct __attribute__((objc_boxable)) CGPoint CGPoint;
typedef struct __attribute__((objc_boxable)) CGSize CGSize;
typedef struct __attribute__((objc_boxable)) CGRect CGRect;
typedef struct __attribute__((objc_boxable)) CGVector CGVector;
typedef struct __attribute__((objc_boxable)) UIEdgeInsets UIEdgeInsets;
typedef struct __attribute__((objc_boxable)) _NSRange NSRange;

@protocol CRFastEnumeration <NSFastEnumeration>
- (id)cr_enumeratedType;
@end

// Usage: foreach (s, strings) { ... }
#define foreach(element, collection) for (typeof((collection).cr_enumeratedType) element in (collection))

@interface NSArray <ElementType> (CRFastEnumeration) <CRFastEnumeration>
- (ElementType)cr_enumeratedType;
@end

@interface NSSet <ElementType> (CRFastEnumeration) <CRFastEnumeration>
- (ElementType)cr_enumeratedType;
@end

@interface NSDictionary <KeyType, ValueType> (CRFastEnumeration) <CRFastEnumeration>
- (KeyType)cr_enumeratedType;
@end

// Geometry

#define CR_CGFLOAT_MAX 32768
#define CR_CGFLOAT_UNDEFINED YGUndefined
#define CR_CGFLOAT_FLEXIBLE CR_CGFLOAT_MAX
#define CR_NORMALIZE(value) (value >= 0.0 && value <= CR_CGFLOAT_MAX ? value : 0.0)

#endif /* CRMacros_h */
