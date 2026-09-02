package org.big.erd.ide.diagram.actions

import com.google.inject.Inject
import org.eclipse.lsp4j.Range
import org.eclipse.lsp4j.TextEdit
import org.eclipse.lsp4j.WorkspaceEdit
import org.eclipse.sprotty.SModelIndex
import org.eclipse.sprotty.SModelElement
import org.eclipse.sprotty.xtext.ILanguageAwareDiagramServer
import org.eclipse.sprotty.xtext.WorkspaceEditAction
import org.eclipse.sprotty.xtext.tracing.PositionConverter
import org.eclipse.xtext.resource.ILocationInFileProvider
import org.eclipse.xtext.ide.server.ILanguageServerAccess
import org.eclipse.xtext.ide.server.UriExtensions
import org.big.erd.entityRelationship.Hierarchy
import org.big.erd.ide.diagram.HierarchyNode

import static org.big.erd.entityRelationship.EntityRelationshipPackage.Literals.*

class EditHierarchyHandler {

	@Inject extension PositionConverter
	@Inject ILocationInFileProvider locationInFileProvider
	@Inject UriExtensions uriExtensions

	/**
	 * Gestiona la edición de las propiedades de jerarquía
	 * directamente desde el nodo de la jerarquía.
	 */
	def handle(EditHierarchyAction action, ILanguageAwareDiagramServer server) {

		val node = new SModelIndex(server.model).get(action.elementId)

		if (node !== null && node instanceof HierarchyNode) {

			server.diagramLanguageServer.languageServerAccess.doRead(
				server.sourceUri,
				[ context |

					val resolvedHierarchy = node.resolveElement(context)

					if (resolvedHierarchy instanceof Hierarchy) {

						val hierarchy = resolvedHierarchy as Hierarchy
						val textEdits = newArrayList

						// Alterna la completitud entre total y partial.
						if (action.property == 'completeness') {

							val textRegion = locationInFileProvider.getFullTextRegion(
								hierarchy,
								HIERARCHY__COMPLETENESS,
								-1
							)

							val startPosition = toPosition(
								textRegion.offset,
								hierarchy
							)

							val endPosition = toPosition(
								textRegion.offset + textRegion.length,
								hierarchy
							)

							val newText =
								if (hierarchy.completeness.literal == 'total')
									'partial'
								else
									'total'

							textEdits += new TextEdit(
								new Range(startPosition, endPosition),
								newText
							)

						// Alterna la restricción entre disjoint y overlapping.
						} else if (action.property == 'constraint') {

							val textRegion = locationInFileProvider.getFullTextRegion(
								hierarchy,
								HIERARCHY__CONSTRAINT,
								-1
							)

							val startPosition = toPosition(
								textRegion.offset,
								hierarchy
							)

							val endPosition = toPosition(
								textRegion.offset + textRegion.length,
								hierarchy
							)

							val newText =
								if (hierarchy.constraint.literal == 'disjoint')
									'overlapping'
								else
									'disjoint'

							textEdits += new TextEdit(
								new Range(startPosition, endPosition),
								newText
							)
						}

						// Aplica el cambio directamente sobre el documento ERD.
						if (!textEdits.empty) {

							val workspaceEdit = new WorkspaceEdit() => [
								changes = #{
									server.sourceUri -> textEdits
								}
							]

							server.dispatch(
								new WorkspaceEditAction => [
									it.workspaceEdit = workspaceEdit
								]
							)
						}
					}

					return null
				]
			)
		}
	}

	private def resolveElement(
		SModelElement sElement,
		ILanguageServerAccess.Context context
	) {
		if (sElement.trace !== null) {
			val elementURI = sElement.trace.toURI
			return context.resource.resourceSet.getEObject(
				elementURI,
				true
			)
		} else {
			return null
		}
	}

	private def toURI(String path) {
		val parts = path.split('#')

		if (parts.size !== 2)
			throw new IllegalArgumentException(
				'Invalid trace URI ' + path
			)

		return uriExtensions
			.toUri(parts.head)
			.trimQuery
			.appendFragment(parts.last)
	}
}