exports.getSelection = () => document.getSelection()
exports.selectionStartNode = s => () => s.anchorNode
exports.selectionEndNode = s => () => s.focusNode
exports.clearSelection = s => () => s.empty()
exports.isEmptySelection = s => () => s.isCollapsed
