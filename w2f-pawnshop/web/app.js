(function () {
    'use strict';

    const RESOURCE = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'w2f-pawnshop';

    const root = document.getElementById('pawn-root');
    const headerLabel = document.getElementById('pawn-header-label');
    const ownerEl = document.getElementById('pawn-owner');
    const greetingEl = document.getElementById('pawn-greeting');
    const messageEl = document.getElementById('pawn-message');
    const optionsEl = document.getElementById('pawn-options');
    const dialogView = document.getElementById('pawn-dialog-view');
    const sellView = document.getElementById('pawn-sell-view');
    const sellList = document.getElementById('pawn-sell-list');
    const sellEmpty = document.getElementById('pawn-sell-empty');
    const sellStatus = document.getElementById('pawn-sell-status');
    const sellBackBtn = document.getElementById('pawn-sell-back');

    let isOpen = false;
    let currentView = 'dialog';

    const ERROR_MESSAGES = {
        database_not_ready: 'The ledger is still loading. Try again in a moment.',
        invalid_item: 'That item cannot be sold here.',
        invalid_amount: 'Invalid quantity.',
        not_owned: 'You no longer have that item.',
        remove_failed: 'Could not remove item from your inventory.',
        payment_failed: 'Payment failed — sale reversed.',
        price_violation: 'Price validation failed.',
        no_framework: 'No supported framework detected for payouts.',
        no_identifier: 'Could not verify your character.',
        unknown: 'Something went wrong.',
    };

    function post(event, data) {
        return fetch(`https://${RESOURCE}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {}),
        }).catch(function () {});
    }

    function formatMoney(value) {
        return '$' + Number(value || 0).toLocaleString('en-US');
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

    function showSellStatus(text, isError) {
        if (!text) {
            sellStatus.classList.add('hidden');
            sellStatus.textContent = '';
            return;
        }
        sellStatus.textContent = text;
        sellStatus.classList.remove('hidden');
        sellStatus.classList.toggle('pawn-sell-status-error', !!isError);
    }

    function setView(view) {
        currentView = view;
        const isSell = view === 'sell';
        dialogView.classList.toggle('hidden', isSell);
        sellView.classList.toggle('hidden', !isSell);
        headerLabel.textContent = isSell ? 'Counter' : 'Pawnshop Owner';
    }

    function openRoot() {
        root.classList.remove('hidden', 'closing');
        root.classList.add('visible');
        root.setAttribute('aria-hidden', 'false');
        isOpen = true;
    }

    function openDialog(payload) {
        ownerEl.textContent = payload.ownerName || 'Owner';
        greetingEl.textContent = payload.greeting || '';
        clearMessage();
        setView('dialog');
        openRoot();
    }

    function closeDialog(sendCallback) {
        if (!isOpen && root.classList.contains('hidden')) return;

        isOpen = false;
        currentView = 'dialog';
        root.classList.add('closing');
        root.setAttribute('aria-hidden', 'true');

        window.setTimeout(function () {
            root.classList.remove('visible', 'closing');
            root.classList.add('hidden');
            setView('dialog');
            clearMessage();
            sellList.innerHTML = '';
            showSellStatus('');
        }, 180);

        if (sendCallback) {
            post('closeDialog', {});
        }
    }

    function renderSellItem(item) {
        const card = document.createElement('div');
        card.className = 'pawn-sell-card';
        card.dataset.item = item.name;

        const bonusLine = item.bonus > 0
            ? `<span class="pawn-sell-bonus">+${formatMoney(item.bonus)} bonus</span>`
            : '<span class="pawn-sell-bonus pawn-sell-bonus-none">No bonus</span>';

        card.innerHTML = `
            <div class="pawn-sell-card-top">
                <img class="pawn-sell-img" src="${item.image}" alt="" />
                <div class="pawn-sell-meta">
                    <span class="pawn-sell-name">${item.label}</span>
                    <span class="pawn-sell-owned">You have: <strong>${item.owned}</strong></span>
                </div>
            </div>
            <div class="pawn-sell-prices">
                <div class="pawn-sell-price-row">
                    <span>Base</span>
                    <span>${formatMoney(item.baseSellPrice)}</span>
                </div>
                <div class="pawn-sell-price-row">
                    <span>Bonus</span>
                    ${bonusLine}
                </div>
                <div class="pawn-sell-price-row pawn-sell-price-final">
                    <span>Offer</span>
                    <span>${formatMoney(item.finalSellPrice)} each</span>
                </div>
            </div>
            <div class="pawn-sell-actions">
                <button type="button" class="pawn-sell-btn" data-sell="1" data-item="${item.name}">Sell 1</button>
                <button type="button" class="pawn-sell-btn pawn-sell-btn-alt" data-sell="all" data-item="${item.name}">Sell All</button>
            </div>
        `;

        return card;
    }

    function renderSellMenu(payload) {
        sellList.innerHTML = '';
        const items = payload.items || [];

        if (!payload.ok) {
            showSellStatus(ERROR_MESSAGES[payload.error] || ERROR_MESSAGES.unknown, true);
            sellEmpty.classList.add('hidden');
            return;
        }

        if (items.length === 0) {
            sellEmpty.classList.remove('hidden');
            return;
        }

        sellEmpty.classList.add('hidden');
        items.forEach(function (item) {
            sellList.appendChild(renderSellItem(item));
        });
    }

    function openSellMenu(payload) {
        setView('sell');
        openRoot();
        showSellStatus('');
        renderSellMenu(payload);
    }

    function updateSellMenu(payload) {
        if (payload.sold) {
            showSellStatus(
                `Sold ${payload.sold.amount} for ${formatMoney(payload.sold.totalPrice)}.`,
                false
            );
        }
        renderSellMenu(payload);
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

    sellBackBtn.addEventListener('click', function () {
        post('sellBack', {});
    });

    sellList.addEventListener('click', function (e) {
        const btn = e.target.closest('[data-sell]');
        if (!btn) return;

        post('sellItem', {
            item: btn.getAttribute('data-item'),
            amount: btn.getAttribute('data-sell') === 'all' ? 'all' : 1,
        });
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
            case 'openSellMenu':
                openSellMenu(data);
                break;
            case 'updateSellMenu':
                updateSellMenu(data);
                break;
            case 'sellError':
                showSellStatus(ERROR_MESSAGES[data.error] || ERROR_MESSAGES.unknown, true);
                break;
            default:
                break;
        }
    });
})();
