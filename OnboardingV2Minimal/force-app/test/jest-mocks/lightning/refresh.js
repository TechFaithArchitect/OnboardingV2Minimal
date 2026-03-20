export class RefreshEvent extends CustomEvent {
    constructor() {
        super('refresh');
    }
}

export const registerRefreshHandler = jest.fn(() => 'refresh-handler-id');
export const unregisterRefreshHandler = jest.fn();
