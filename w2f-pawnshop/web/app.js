(function () {
    'use strict';

    const RESOURCE = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'w2f-pawnshop';

    const root = document.getElementById('pawn-root');
    const panel = document.getElementById('pawn-panel');
    const headerLabel = document.getElementById('pawn-header-label');
    const ownerEl = document.getElementById('pawn-owner');
    const greetingEl = document.getElementById('pawn-greeting');
    const messageEl = document.getElementById('pawn-message');
    const optionsEl = document.getElementById('pawn-options');
    const dialogView = document.getElementById('pawn-dialog-view');
    const sellView = document.getElementById('pawn-sell-view');
    const storefrontView = document.getElementById('pawn-storefront-view');
    const sellList = document.getElementById('pawn-sell-list');
    const sellEmpty = document.getElementById('pawn-sell-empty');
    const sellStatus = document.getElementById('pawn-sell-status');
    const sellBackBtn = document.getElementById('pawn-sell-back');
    const storeBackBtn = document.getElementById('pawn-store-back');
    const checkoutBtn = document.getElementById('pawn-checkout-btn');
    const rejectionView = document.getElementById('pawn-rejection-view');
    const rejectionClose = document.getElementById('pawn-rejection-close');
    const loadingEl = document.getElementById('pawn-loading');
    let uiBusy = false;
    const loyaltyStrip = document.getElementById('pawn-loyalty-strip');
    const sellLoyaltyPanel = document.getElementById('pawn-sell-loyalty');
    const sellDemandedEl = document.getElementById('pawn-sell-demanded');
    const blackMarketBtn = document.getElementById('pawn-option-blackmarket');

    let isOpen = false;
    let currentView = 'dialog';

    const ERROR_MESSAGES = {
        database_not_ready: 'The ledger is still loading. Try again in a moment.',
        invalid_item: 'Invalid item.',
        invalid_amount: 'Invalid quantity.',
        invalid_cart: 'Invalid cart.',
        empty_cart: 'Your cart is empty.',
        cart_limit: 'Cart exceeds the maximum per checkout.',
        insufficient_stock: 'Not enough stock for that item.',
        insufficient_funds: 'You cannot afford this purchase.',
        loyalty_locked: 'Your loyalty level is too low for an item in your cart.',
        loyalty_too_low: 'You need more reputation before the dealer will see you.',
        busy: 'Please wait for the current action to finish.',
        inventory_full: 'Not enough inventory space.',
        payment_failed: 'Payment failed.',
        not_owned: 'You no longer have that item.',
        remove_failed: 'Could not remove item from your inventory.',
        price_violation: 'Price validation failed.',
        no_framework: 'No supported framework detected.',
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

    function renderLoyaltyHtml(loyalty, compact) {
        if (!loyalty) return '';

        var progress = loyalty.nextLevel
            ? ('<div class="pawn-loyalty-progress"><div class="pawn-loyalty-progress-fill" style="width:' + loyalty.progressPercent + '%"></div></div>' +
               '<span class="pawn-loyalty-progress-text">' + loyalty.xp + ' / ' + loyalty.nextLevelXp + ' XP</span>')
            : '<span class="pawn-loyalty-maxed">Max reputation</span>';

        if (compact) {
            return (
                '<div class="pawn-loyalty-compact">' +
                '<span class="pawn-loyalty-level">Lv ' + loyalty.level + ' · ' + loyalty.label + '</span>' +
                '<span class="pawn-loyalty-perks">+' + loyalty.sellBonusPercent + '% sell · -' + loyalty.buyDiscountPercent + '% buy</span>' +
                progress +
                '</div>'
            );
        }

        return (
            '<div class="pawn-loyalty-full">' +
            '<div class="pawn-loyalty-row"><span>Reputation</span><strong>Lv ' + loyalty.level + ' — ' + loyalty.label + '</strong></div>' +
            '<div class="pawn-loyalty-row"><span>XP</span><strong>' + loyalty.xp + (loyalty.nextLevelXp ? (' → ' + loyalty.nextLevelXp) : '') + '</strong></div>' +
            progress +
            '<div class="pawn-loyalty-row"><span>Sell bonus</span><strong>+' + loyalty.sellBonusPercent + '%</strong></div>' +
            '<div class="pawn-loyalty-row"><span>Buy discount</span><strong>-' + loyalty.buyDiscountPercent + '%</strong></div>' +
            '</div>'
        );
    }

    function applyLoyaltyStrip(loyalty, blackMarketUnlock) {
        if (!loyaltyStrip) return;

        if (!loyalty) {
            loyaltyStrip.classList.add('hidden');
            loyaltyStrip.innerHTML = '';
        } else {
            loyaltyStrip.classList.remove('hidden');
            loyaltyStrip.innerHTML = renderLoyaltyHtml(loyalty, true);
        }

        if (blackMarketBtn) {
            blackMarketBtn.classList.toggle('hidden', !blackMarketUnlock);
        }
    }

    function applySellLoyalty(payload) {
        if (sellLoyaltyPanel) {
            if (payload.loyalty) {
                sellLoyaltyPanel.classList.remove('hidden');
                sellLoyaltyPanel.innerHTML = renderLoyaltyHtml(payload.loyalty, false);
            } else {
                sellLoyaltyPanel.classList.add('hidden');
            }
        }

        if (sellDemandedEl) {
            var demanded = payload.demanded || [];
            if (demanded.length > 0) {
                var names = demanded.slice(0, 2).map(function (d) { return d.label; });
                sellDemandedEl.textContent = 'In demand: ' + names.join(', ');
                sellDemandedEl.classList.remove('hidden');
            } else {
                sellDemandedEl.classList.add('hidden');
            }
        }
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

    function setBusy(busy) {
        uiBusy = !!busy;
        if (loadingEl) {
            loadingEl.classList.toggle('hidden', !uiBusy);
        }
        document.querySelectorAll('.pawn-sell-btn, .pawn-store-add, .pawn-checkout-btn, .pawn-option').forEach(function (el) {
            if (uiBusy) el.setAttribute('disabled', 'disabled');
            else el.removeAttribute('disabled');
        });
    }

    function setView(view) {
        currentView = view;
        var isStore = view === 'storefront' || view === 'blackmarket';

        dialogView.classList.toggle('hidden', view !== 'dialog');
        sellView.classList.toggle('hidden', view !== 'sell');
        storefrontView.classList.toggle('hidden', !isStore);
        if (rejectionView) rejectionView.classList.toggle('hidden', view !== 'rejection');

        panel.classList.toggle('pawn-dialog-storefront', isStore);
        panel.classList.toggle('pawn-theme-bm', view === 'blackmarket');
        root.classList.toggle('pawn-root-storefront', isStore);

        if (view === 'sell') {
            headerLabel.textContent = 'Counter';
        } else if (view === 'blackmarket') {
            headerLabel.textContent = 'Black Market';
        } else if (view === 'storefront') {
            headerLabel.textContent = 'Storefront';
        } else if (view === 'rejection') {
            headerLabel.textContent = 'Access Denied';
        } else {
            headerLabel.textContent = 'Pawnshop Owner';
        }
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
        applyLoyaltyStrip(payload.loyalty, payload.blackMarketUnlock);
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
            if (window.W2FStorefront) W2FStorefront.reset();
        }, 180);

        if (sendCallback) {
            post('closeDialog', {});
        }
    }

    function renderSellItem(item) {
        const card = document.createElement('div');
        card.className = 'pawn-sell-card' + (item.demanded ? ' pawn-sell-card-demanded' : '');

        const demandBadge = item.demanded
            ? '<span class="pawn-demand-badge">In demand</span>'
            : '';

        const loyaltyLine = item.loyaltyBonus > 0
            ? `<span class="pawn-sell-bonus">+${formatMoney(item.loyaltyBonus)} loyalty</span>`
            : '<span class="pawn-sell-bonus pawn-sell-bonus-none">—</span>';

        const demandLine = item.demandBonus > 0
            ? `<span class="pawn-sell-bonus pawn-sell-bonus-demand">+${formatMoney(item.demandBonus)} demand</span>`
            : '<span class="pawn-sell-bonus pawn-sell-bonus-none">—</span>';

        card.innerHTML = `
            <div class="pawn-sell-card-top">
                <img class="pawn-sell-img" src="${item.image}" alt="" />
                <div class="pawn-sell-meta">
                    <span class="pawn-sell-name">${item.label} ${demandBadge}</span>
                    <span class="pawn-sell-owned">You have: <strong>${item.owned}</strong></span>
                </div>
            </div>
            <div class="pawn-sell-prices">
                <div class="pawn-sell-price-row">
                    <span>Base</span>
                    <span>${formatMoney(item.baseSellPrice)}</span>
                </div>
                <div class="pawn-sell-price-row">
                    <span>Loyalty</span>
                    ${loyaltyLine}
                </div>
                <div class="pawn-sell-price-row">
                    <span>Demand</span>
                    ${demandLine}
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
        applySellLoyalty(payload);
        renderSellMenu(payload);
    }

    function updateSellMenu(payload) {
        if (payload.sold) {
            var xp = payload.sold.loyaltyXp ? (' +' + payload.sold.loyaltyXp + ' XP') : '';
            showSellStatus(
                'Sold ' + payload.sold.amount + ' for ' + formatMoney(payload.sold.totalPrice) + xp + '.',
                false
            );
        }
        if (payload.loyalty) applySellLoyalty(payload);
        renderSellMenu(payload);
    }

    function openRejection(payload) {
        var title = document.getElementById('pawn-rejection-title');
        var msg = document.getElementById('pawn-rejection-msg');
        if (title) title.textContent = payload.title || 'Access Denied';
        if (msg) msg.textContent = payload.message || '';
        ownerEl.textContent = payload.title || 'Dealer';
        setView('rejection');
        openRoot();
    }

    function openStorefront(payload) {
        var view = payload.theme === 'blackmarket' ? 'blackmarket' : 'storefront';
        if (payload.dealerName) ownerEl.textContent = payload.dealerName;
        if (payload.greeting && view === 'blackmarket') {
            showMessage(payload.greeting);
        }
        setView(view);
        openRoot();
        if (window.W2FStorefront) W2FStorefront.open(payload);
    }

    function updateStorefront(payload) {
        if (window.W2FStorefront) W2FStorefront.update(payload);
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

    storeBackBtn.addEventListener('click', function () {
        post('storefrontBack', {});
    });

    sellList.addEventListener('click', function (e) {
        const btn = e.target.closest('[data-sell]');
        if (!btn) return;

        post('sellItem', {
            item: btn.getAttribute('data-item'),
            amount: btn.getAttribute('data-sell') === 'all' ? 'all' : 1,
        });
    });

    checkoutBtn.addEventListener('click', function () {
        if (uiBusy || !window.W2FStorefront || W2FStorefront.viewOnly) return;
        post('checkout', {
            cart: W2FStorefront.getCartPayload(),
            shop: W2FStorefront.getShop ? W2FStorefront.getShop() : 'pawnshop',
        });
    });

    if (rejectionClose) {
        rejectionClose.addEventListener('click', function () {
            post('rejectionClose', {});
        });
    }

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
            case 'setBusy':
                setBusy(data.busy);
                break;
            case 'openDialog':
                openDialog(data);
                break;
            case 'closeDialog':
                closeDialog(false);
                break;
            case 'showMessage':
                showMessage(data.message);
                break;
            case 'openRejection':
                openRejection(data);
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
            case 'openStorefront':
                openStorefront(data);
                break;
            case 'updateStorefront':
                updateStorefront(data);
                break;
            case 'storefrontError': {
                var msg = ERROR_MESSAGES[data.error] || ERROR_MESSAGES.unknown;
                if (data.item) msg += ' (' + data.item + ')';
                const status = document.getElementById('pawn-store-status');
                if (status) {
                    status.textContent = msg;
                    status.classList.remove('hidden');
                    status.classList.add('pawn-store-status-error');
                }
                break;
            }
            default:
                break;
        }
    });
})();
