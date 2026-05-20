(function () {
    'use strict';

    const RESOURCE = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'w2f-pawnshop';

    const root = document.getElementById('pawn-root');
    const ownerEl = document.getElementById('pawn-owner');
    const greetingEl = document.getElementById('pawn-greeting');
    const messageEl = document.getElementById('pawn-message');
    const optionsEl = document.getElementById('pawn-options');

    let isOpen = false;

    function post(event, data) {
        return fetch(`https://${RESOURCE}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {}),
        }).catch(function () {});
    }

    function clearMessage() {
        messageEl.textContent = '';
        messageEl.classList.add('hidden');
    }

    function showMessage(text) {
        if (!text) return;
        messageEl.textContent = text;
        messageEl.classList.remove('hidden');
    }

    function openDialog(payload) {
        ownerEl.textContent = payload.ownerName || 'Owner';
        greetingEl.textContent = payload.greeting || '';
        clearMessage();

        root.classList.remove('hidden', 'closing');
        root.classList.add('visible');
        root.setAttribute('aria-hidden', 'false');
        isOpen = true;
    }

    function closeDialog(sendCallback) {
        if (!isOpen && root.classList.contains('hidden')) return;

        isOpen = false;
        root.classList.add('closing');
        root.setAttribute('aria-hidden', 'true');

        window.setTimeout(function () {
            root.classList.remove('visible', 'closing');
            root.classList.add('hidden');
            clearMessage();
        }, 180);

        if (sendCallback) {
            post('closeDialog', {});
        }
    }

    function onChoice(choice) {
        if (!choice) return;

        if (choice === 'nevermind') {
            post('dialogSelect', { choice: 'nevermind' });
            closeDialog(false);
            return;
        }

        post('dialogSelect', { choice: choice });
    }

    optionsEl.addEventListener('click', function (e) {
        const btn = e.target.closest('[data-choice]');
        if (!btn) return;
        onChoice(btn.getAttribute('data-choice'));
    });

    document.querySelectorAll('[data-close]').forEach(function (el) {
        el.addEventListener('click', function () {
            closeDialog(true);
        });
    });

    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape' || !isOpen) return;
        e.preventDefault();
        post('escape', {});
        closeDialog(false);
    });

    window.addEventListener('message', function (event) {
        const data = event.data || {};

        switch (data.action) {
            case 'openDialog':
                openDialog(data);
                break;
            case 'closeDialog':
                closeDialog(false);
                break;
            case 'showMessage':
                showMessage(data.message);
                break;
            default:
                break;
        }
    });
})();
