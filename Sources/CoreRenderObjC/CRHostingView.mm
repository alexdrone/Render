#include "CRHostingView.h"

#include "CRContext.h"
#include "CRMacros.h"
#include "CRNode.h"
#include "CRNodeBuilder.h"
#include "CRNodeHierarchy.h"

@implementation CRHostingView {
  __weak CRContext *_context;
  CRNodeLayoutOptions _options;
  CRNodeHierarchy *_body;
}

- (instancetype)initWithContext:(CRContext *)context
                    withOptions:(CRNodeLayoutOptions)options
                           body:(CROpaqueNodeBuilder * (^)(CRContext *))buildBody {
  if (self = [super initWithFrame:CGRectZero]) {
    if (@available(iOS 13, *)) {
      self.backgroundColor = [UIColor systemBackgroundColor];
    } else {
      self.backgroundColor = [UIColor whiteColor];
    }
    _context = context;
    _options = options;
    _body = [[CRNodeHierarchy alloc] initWithContext:context nodeHierarchyBuilder:buildBody];
    [_body buildHierarchyInView:self constrainedToSize:self.bounds.size withOptions:options];
  }
  return self;
}

- (void)setNeedsReconcile {
  CR_ASSERT_ON_MAIN_THREAD();
  [_body reconcileInView:self constrainedToSize:self.bounds.size withOptions:_options];
}

- (void)setNeedsLayout {
  CR_ASSERT_ON_MAIN_THREAD();
  [_body layoutConstrainedToSize:self.bounds.size withOptions:_options];
}

@end
