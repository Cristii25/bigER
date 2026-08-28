import { injectable } from "inversify";
import { ActionHandlerRegistry } from "sprotty";
import { Action } from 'sprotty-protocol';
import { VscodeLspEditDiagramServer } from "sprotty-vscode-webview/lib/lsp/editing";
import { AddAttributeAction, ChangeNotationAction, CreateElementEditAction, EditHierarchyAction } from "./actions";

@injectable()
export class BigERDiagramServer extends VscodeLspEditDiagramServer {
    override initialize(registry: ActionHandlerRegistry): void {
        super.initialize(registry);
        registry.register(ChangeNotationAction.KIND, this);
        registry.register(CreateElementEditAction.KIND, this);
        registry.register(AddAttributeAction.KIND, this);
        // Registra la acción de edición de propiedades de jerarquía.
        registry.register(EditHierarchyAction.KIND, this);
    }

    /**
     * Check which actions should be handled on the server by returning true. If false,
     * the action is handled locally (slightly counter-intuitive with the method's name).
     */
    override handleLocally(action: Action): boolean {
        switch (action.kind) {
            case ChangeNotationAction.KIND:
            case CreateElementEditAction.KIND:
            case AddAttributeAction.KIND:
            case EditHierarchyAction.KIND:
                return true;
            default:
                return super.handleLocally(action);
        }
    }
}