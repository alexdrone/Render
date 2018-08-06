#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRController <P, S> ()
// Private setter modifiers
@property(nonatomic, readwrite) NSString *key;
@property(nonatomic, readwrite, nullable, weak) CRContext *context;
@property(nonatomic, readwrite, nullable, weak) CRNode *node;

/// @note: Never call the init method manually - controllers are dynamically constructed,
/// disposed and reused by @c CRContext.
- (instancetype)initWithKey:(NSString*)key;

@end

//template <typename T, typename S, typename P>
//inline void CRInjectInitialStateAndProps(CRController<S, P> * _Nullable controller) {
//  if (!controller) return;
//  controller.state = CR_NIL_COALESCING(controller.state, [[S alloc] init]);
//  controller.state = CR_NIL_COALESCING(controller.props, [[P alloc] init]);
//}

NS_ASSUME_NONNULL_END
