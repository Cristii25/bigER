package org.big.erd.ide.diagram

import org.eclipse.sprotty.Action
import org.eclipse.sprotty.xtext.LanguageAwareDiagramServer
import com.google.inject.Inject
import org.big.erd.ide.diagram.actions.AddAttributeHandler
import org.big.erd.ide.diagram.actions.CreateElementHandler
import org.big.erd.ide.diagram.actions.NotationHandler
import org.big.erd.ide.diagram.actions.ChangeNotationAction
import org.big.erd.ide.diagram.actions.CreateElementEditAction
import org.big.erd.ide.diagram.actions.AddAttributeAction
import org.big.erd.ide.diagram.actions.EditHierarchyAction
import org.big.erd.ide.diagram.actions.EditHierarchyHandler

class ERDiagramServer extends LanguageAwareDiagramServer {

	@Inject NotationHandler notationHandler
	@Inject CreateElementHandler createElementHandler
	@Inject AddAttributeHandler addAttributeHandler
	// Handler encargado de aplicar las modificaciones de las propiedades de jerarquía.
	@Inject EditHierarchyHandler editHierarchyHandler

	override protected handleAction(Action action) {
		if (action.kind === ChangeNotationAction.KIND) {
			notationHandler.handle(action as ChangeNotationAction, this)
		} else if (action.kind === CreateElementEditAction.KIND) {
			createElementHandler.handle(action as CreateElementEditAction, this)
		} else if (action.kind === AddAttributeAction.KIND) {
			addAttributeHandler.handle(action as AddAttributeAction, this)
		// Delega las acciones de edición de jerarquía en su handler específico.
		} else if (action.kind === EditHierarchyAction.KIND) {
			editHierarchyHandler.handle(action as EditHierarchyAction, this)
		} else {
			super.handleAction(action)
		}
	}
}