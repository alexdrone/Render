#import "CRUmbrellaHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRContext : NSObject
/// Layout animator for the nodes registered to this context.
@property (nonatomic, nullable) UIViewPropertyAnimator *layoutAnimator;
@end

NS_ASSUME_NONNULL_END
