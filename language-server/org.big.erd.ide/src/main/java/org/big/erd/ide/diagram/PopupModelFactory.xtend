package org.big.erd.ide.diagram

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.sprotty.HtmlRoot
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.IPopupModelFactory
import org.eclipse.sprotty.PreRenderedElement
import org.eclipse.sprotty.RequestPopupModelAction
import org.eclipse.sprotty.SIssueMarker
import org.eclipse.sprotty.SModelElement
import org.eclipse.sprotty.xtext.ILanguageAwareDiagramServer
import org.eclipse.sprotty.xtext.tracing.ITraceProvider
import org.big.erd.entityRelationship.Entity
import org.big.erd.entityRelationship.Relationship
import org.big.erd.entityRelationship.Model
import org.big.erd.entityRelationship.Hierarchy
import java.util.ArrayList
import org.big.erd.entityRelationship.DataType

class PopupModelFactory implements IPopupModelFactory {

	@Inject extension ITraceProvider

	override createPopupModel(SModelElement element, RequestPopupModelAction request, IDiagramServer server) {
		switch element {
			SIssueMarker: {
				val popupId = element.id + '-popup'
				new HtmlRoot [
					id = popupId
					children = #[
						new PreRenderedElement [
							id = popupId + '-body'
							code = '''«getIssueRow(element)»'''
						]
					]
					canvasBounds = request.bounds
				]
			}
			case null:
				null
			default: {
				val future = element.withSource(server as ILanguageAwareDiagramServer) [ semanticElement, context |
					semanticElement?.createPopup(element, request) ?: null
				]
				future.get
			}
		}
	}

	protected def CharSequence getIssueRow(SIssueMarker element) {
		'''
			<div class="sprotty-infoBlock">
				<div class="sprotty-infoRow">
					«FOR issue : element.issues»
						<div class="sprotty-infoText">
							<i class="fa «issue.severity.iconClass» sprotty-«issue.severity»" />«issue.message»
						</div>
					«ENDFOR»
				</div>
			</div>
		'''
	}

	protected def getIconClass(String severity) {
		switch severity {
			case 'error',
			case 'warning': 'fa-exclamation-circle'
			case 'info': 'fa-info-circle'
		}
	}

	/*
 	Construye el contenido del popup utilizando botones HTML
 	para poder controlar completamente su apariencia mediante CSS
 	y mantener un diseño uniforme en todos los temas de VS Code.
 	*/
	protected def createPopup(EObject semanticElement, SModelElement element, RequestPopupModelAction request) {
		val popupId = element.id + '-popup'
		val issueMarker = element.children?.filter(SIssueMarker)?.head
		var hierarchy = null as Hierarchy

		// Busca la jerarquía asociada cuando la entidad seleccionada es una entidad base.
		if (semanticElement instanceof Entity) {
			val model = semanticElement.eContainer
			if (model instanceof Model) {
				hierarchy = model.hierarchies.findFirst[
					base === semanticElement
				]
			}
		}

		val popupChildren = new ArrayList<SModelElement>

		popupChildren.add(
			new PreRenderedElement [
				id = popupId + '-body'
				children = new ArrayList<SModelElement>
				code = '''
					<div class="sprotty-infoBlock">
					«IF issueMarker !== null»
						«getIssueRow(issueMarker)»
					«ENDIF»
					«getHeader(semanticElement)»
					</div>
				'''
			]
		)

		popupChildren.add(
			new PopupButton [
				id = popupId + '-editButton'
				type = 'button:edit'
				target = element.id + '.label'
				kind = 'edit'
				code = '''
					<button type="button" class="popup-button">
						<span class="codicon codicon-edit"></span>
						<span class="popup-button-label">Rename</span>
					</button>
				'''
			]
		)

		popupChildren.add(
			new PopupButton [
				id = popupId + '-deleteButton'
				type = 'button:delete'
				target = element.id
				kind = 'delete'
				code = '''
					<button type="button" class="popup-button">
						<span class="codicon codicon-trash"></span>
						<span class="popup-button-label">Delete</span>
					</button>
				'''
			]
		)

		popupChildren.add(
			new PopupButton [
				id = popupId + '-addAttributeButton'
				type = 'button:addAttribute'
				target = element.id
				kind = 'addAttribute'
				code = '''
					<button type="button" class="popup-button">
						<span class="codicon codicon-add"></span>
						<span class="popup-button-label">Add Attribute</span>
					</button>
				'''
			]
		)

		// Los controles de jerarquía solo se muestran para entidades base
		// que tengan una declaración hierarchy asociada.
		if (hierarchy !== null) {

			// El texto del botón muestra siempre el valor alternativo disponible.
			val completenessLabel =
				if (hierarchy.completeness.literal === 'total')
					'Set Partial'
				else
					'Set Total'

			val constraintLabel =
				if (hierarchy.constraint.literal === 'disjoint')
					'Set Overlapping'
				else
					'Set Disjoint'

			// Botón para alternar entre jerarquía total y parcial.
			popupChildren.add(
				new PopupButton [
					id = popupId + '-hierarchyCompletenessButton'
					type = 'button:toggleHierarchyCompleteness'
					target = element.id
					kind = 'toggleHierarchyCompleteness'
					code = '''
						<button type="button" class="popup-button">
							<span class="codicon codicon-edit"></span>
							<span class="popup-button-label">«completenessLabel»</span>
						</button>
					'''
				]
			)

			// Botón para alternar entre jerarquía disjunta y solapada.
			popupChildren.add(
				new PopupButton [
					id = popupId + '-hierarchyConstraintButton'
					type = 'button:toggleHierarchyConstraint'
					target = element.id
					kind = 'toggleHierarchyConstraint'
					code = '''
						<button type="button" class="popup-button">
							<span class="codicon codicon-edit"></span>
							<span class="popup-button-label">«constraintLabel»</span>
						</button>
					'''
				]
			)
		}

		val htmlRoot = new HtmlRoot [
			id = popupId
			children = popupChildren
			canvasBounds = request.bounds
		]

		return htmlRoot
	}

	/*
 	Genera la cabecera del popup separando la etiqueta del tipo
 	y el nombre del elemento para facilitar su alineación y permitir
 	que el ancho del popup se adapte al contenido.
 	*/
	protected def String getHeader(EObject semanticElement) {
		'''
			<div class="popup-header">
				«IF semanticElement instanceof Entity»
					<div class="popup-element-info">
						<vscode-tag class="popup-tag">Entity</vscode-tag>
						<span class="popup-element-name">«semanticElement.name»</span>
					</div>
				«ENDIF»
				«IF semanticElement instanceof Relationship»
					<div class="popup-element-info">
						<vscode-tag class="popup-tag">Relationship</vscode-tag>
						<span class="popup-element-name">«semanticElement.name»</span>
					</div>
				«ENDIF»
			</div>
		'''
	}

	private def transformDataType(DataType dataType) {
		// default
		if (dataType === null) {
			return ''
		}

		val type = dataType.type
		var size = dataType.size

		if (size != 0) {
			return type + '(' + size + ')';
		}

		return type
	}
}
