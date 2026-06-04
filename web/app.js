(function () {
    'use strict';

    var DEBUG_PREFIX = '[w2f-pawnshop][nui]';
    var RESOURCE = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'w2f-pawnshop';

    function log() {
        var args = Array.prototype.slice.call(arguments);
        args.unshift(DEBUG_PREFIX);
        console.log.apply(console, args);
    }

    function warn() {
        var args = Array.prototype.slice.call(arguments);
        args.unshift(DEBUG_PREFIX);
        console.warn.apply(console, args);
    }

    function error() {
        var args = Array.prototype.slice.call(arguments);
        args.unshift(DEBUG_PREFIX);
        console.error.apply(console, args);
    }

    function byId(id, required) {
        var el = document.getElementById(id);
        if (!el && required !== false) {
            error('DOM lookup failed: #' + id + ' is missing from web/index.html');
        }
        return el;
    }

    function safeText(el, text, name) {
        if (!el) {
            error('Cannot set text; missing element:', name);
            return false;
        }
        el.textContent = text == null ? '' : String(text);
        return true;
    }

    function addClass(el, className, name) {
        if (!el) {
            error('Cannot add class; missing element:', name || className);
            return false;
        }
        el.classList.add(className);
        return true;
    }

    function removeClass(el, className, name) {
        if (!el) {
            error('Cannot remove class; missing element:', name || className);
            return false;
        }
        el.classList.remove(className);
        return true;
    }

    function toggleClass(el, className, state, name) {
        if (!el) {
            error('Cannot toggle class; missing element:', name || className);
            return false;
        }
        el.classList.toggle(className, !!state);
        return true;
    }

    function hide(el, name) {
        return addClass(el, 'hidden', name);
    }

    function show(el, name) {
        return removeClass(el, 'hidden', name);
    }

    function qsa(selector) {
        try {
            return document.querySelectorAll(selector);
        } catch (e) {
            error('querySelectorAll failed:', selector, e);
            return [];
        }
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    var root = byId('pawn-root');
    var panel = byId('pawn-panel');
    var headerLabel = byId('pawn-header-label');
    var ownerEl = byId('pawn-owner');
    var greetingEl = byId('pawn-greeting');
    var messageEl = byId('pawn-message');
    var optionsEl = byId('pawn-options');
    var dialogView = byId('pawn-dialog-view');
    var sellView = byId('pawn-sell-view');
    var storefrontView = byId('pawn-storefront-view');
    var debugView = byId('pawn-debug-view', false);
    var debugMessage = byId('pawn-debug-message', false);
    var sellList = byId('pawn-sell-list');
    var sellEmpty = byId('pawn-sell-empty');
    var sellStatus = byId('pawn-sell-status');
    var sellBackBtn = byId('pawn-sell-back');
    var storeBackBtn = byId('pawn-store-back');
    var checkoutBtn = byId('pawn-checkout-btn');
    var rejectionView = byId('pawn-rejection-view');
    var rejectionClose = byId('pawn-rejection-close');
    var loadingEl = byId('pawn-loading', false);
    var loyaltyStrip = byId('pawn-loyalty-strip', false);
    var sellLoyaltyPanel = byId('pawn-sell-loyalty', false);
    var sellDemandedEl = byId('pawn-sell-demanded', false);
    var blackMarketBtn = byId('pawn-option-blackmarket', false);

    var uiBusy = false;
    var isOpen = false;
    var currentView = 'dialog';

    var ERROR_MESSAGES = {
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
        unknown: 'Something went wrong.'
    };

    function post(event, data) {
        return fetch('https://' + RESOURCE + '/' + event, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        }).catch(function (e) {
            warn('NUI callback failed:', event, e && e.message ? e.message : e);
        });
    }

    function formatMoney(value) {
        return '$' + Number(value || 0).toLocaleString('en-US');
    }

    function clearMessage() {
        if (!messageEl) return error('clearMessage failed: #pawn-message missing');
        messageEl.textContent = '';
        hide(messageEl, 'pawn-message');
    }

    function showMessage(text) {
        if (!text) return;
        if (!messageEl) return error('showMessage failed: #pawn-message missing');
        messageEl.textContent = text;
        show(messageEl, 'pawn-message');
    }

    function renderLoyaltyHtml(loyalty, compact) {
        if (!loyalty) return '';
        var progressPercent = Math.max(0, Math.min(100, Number(loyalty.progressPercent || 0)));
        var progress = loyalty.nextLevel
            ? ('<div class="pawn-loyalty-progress"><div class="pawn-loyalty-progress-fill" style="width:' + progressPercent + '%"></div></div>' +
               '<span class="pawn-loyalty-progress-text">' + escapeHtml(loyalty.xp) + ' / ' + escapeHtml(loyalty.nextLevelXp) + ' XP</span>')
            : '<span class="pawn-loyalty-maxed">Max reputation</span>';

        if (compact) {
            return '<div class="pawn-loyalty-compact">' +
                '<span class="pawn-loyalty-level">Lv ' + escapeHtml(loyalty.level) + ' · ' + escapeHtml(loyalty.label) + '</span>' +
                '<span class="pawn-loyalty-perks">+' + escapeHtml(loyalty.sellBonusPercent) + '% sell · -' + escapeHtml(loyalty.buyDiscountPercent) + '% buy</span>' +
                progress +
                '</div>';
        }

        return '<div class="pawn-loyalty-full">' +
            '<div class="pawn-loyalty-row"><span>Reputation</span><strong>Lv ' + escapeHtml(loyalty.level) + ' — ' + escapeHtml(loyalty.label) + '</strong></div>' +
            '<div class="pawn-loyalty-row"><span>XP</span><strong>' + escapeHtml(loyalty.xp) + (loyalty.nextLevelXp ? (' → ' + escapeHtml(loyalty.nextLevelXp)) : '') + '</strong></div>' +
            progress +
            '<div class="pawn-loyalty-row"><span>Sell bonus</span><strong>+' + escapeHtml(loyalty.sellBonusPercent) + '%</strong></div>' +
            '<div class="pawn-loyalty-row"><span>Buy discount</span><strong>-' + escapeHtml(loyalty.buyDiscountPercent) + '%</strong></div>' +
            '</div>';
    }

    function applyLoyaltyStrip(loyalty, blackMarketUnlock) {
        if (!loyaltyStrip) {
            warn('Skipping loyalty strip: #pawn-loyalty-strip missing');
        } else if (!loyalty) {
            hide(loyaltyStrip, 'pawn-loyalty-strip');
            loyaltyStrip.innerHTML = '';
        } else {
            show(loyaltyStrip, 'pawn-loyalty-strip');
            loyaltyStrip.innerHTML = renderLoyaltyHtml(loyalty, true);
        }

        if (!blackMarketBtn) {
            warn('Skipping black market button toggle: #pawn-option-blackmarket missing');
        } else {
            toggleClass(blackMarketBtn, 'hidden', !blackMarketUnlock, 'pawn-option-blackmarket');
        }
    }

    function applySellLoyalty(payload) {
        payload = payload || {};
        if (sellLoyaltyPanel) {
            if (payload.loyalty) {
                show(sellLoyaltyPanel, 'pawn-sell-loyalty');
                sellLoyaltyPanel.innerHTML = renderLoyaltyHtml(payload.loyalty, false);
            } else {
                hide(sellLoyaltyPanel, 'pawn-sell-loyalty');
            }
        } else {
            warn('Skipping sell loyalty panel: #pawn-sell-loyalty missing');
        }

        if (sellDemandedEl) {
            var demanded = payload.demanded || [];
            if (demanded.length > 0) {
                var names = demanded.slice(0, 2).map(function (d) { return d.label; });
                sellDemandedEl.textContent = 'In demand: ' + names.join(', ');
                show(sellDemandedEl, 'pawn-sell-demanded');
            } else {
                hide(sellDemandedEl, 'pawn-sell-demanded');
            }
        } else {
            warn('Skipping demanded items text: #pawn-sell-demanded missing');
        }
    }

    function showSellStatus(text, isError) {
        if (!sellStatus) return error('showSellStatus failed: #pawn-sell-status missing');
        if (!text) {
            hide(sellStatus, 'pawn-sell-status');
            sellStatus.textContent = '';
            return;
        }
        sellStatus.textContent = text;
        show(sellStatus, 'pawn-sell-status');
        toggleClass(sellStatus, 'pawn-sell-status-error', !!isError, 'pawn-sell-status');
    }

    function setBusy(busy) {
        uiBusy = !!busy;
        if (loadingEl) toggleClass(loadingEl, 'hidden', !uiBusy, 'pawn-loading');
        Array.prototype.forEach.call(qsa('.pawn-sell-btn, .pawn-store-add, .pawn-checkout-btn, .pawn-option'), function (el) {
            if (uiBusy) el.setAttribute('disabled', 'disabled');
            else el.removeAttribute('disabled');
        });
    }

    function setView(view) {
        currentView = view;
        var isStore = view === 'storefront' || view === 'blackmarket';

        toggleClass(dialogView, 'hidden', view !== 'dialog', 'pawn-dialog-view');
        toggleClass(sellView, 'hidden', view !== 'sell', 'pawn-sell-view');
        toggleClass(storefrontView, 'hidden', !isStore, 'pawn-storefront-view');
        if (rejectionView) toggleClass(rejectionView, 'hidden', view !== 'rejection', 'pawn-rejection-view');
        if (debugView) toggleClass(debugView, 'hidden', view !== 'debug', 'pawn-debug-view');

        if (panel) {
            toggleClass(panel, 'pawn-dialog-storefront', isStore, 'pawn-panel');
            toggleClass(panel, 'pawn-theme-bm', view === 'blackmarket', 'pawn-panel');
            toggleClass(panel, 'pawn-debug-panel', view === 'debug', 'pawn-panel');
        }
        if (root) toggleClass(root, 'pawn-root-storefront', isStore, 'pawn-root');

        var label = 'Pawnshop Owner';
        if (view === 'sell') label = 'Counter';
        else if (view === 'blackmarket') label = 'Black Market';
        else if (view === 'storefront') label = 'Storefront';
        else if (view === 'rejection') label = 'Access Denied';
        else if (view === 'debug') label = 'NUI Debug';
        safeText(headerLabel, label, 'pawn-header-label');
    }

    function openRoot() {
        if (!root) return error('openRoot failed: #pawn-root missing');
        root.classList.remove('hidden', 'closing');
        root.classList.add('visible');
        root.style.display = '';
        root.style.visibility = 'visible';
        root.style.opacity = '1';
        root.style.pointerEvents = 'auto';
        root.setAttribute('aria-hidden', 'false');
        isOpen = true;
        log('root forced visible; classes=' + root.className);
    }

    function openDialog(payload) {
        payload = payload || {};
        log('openDialog() called', JSON.stringify(payload));
        safeText(ownerEl, payload.ownerName || 'Owner', 'pawn-owner');
        safeText(greetingEl, payload.greeting || 'How can I help you?', 'pawn-greeting');
        clearMessage();
        applyLoyaltyStrip(payload.loyalty, payload.blackMarketUnlock);
        setView('dialog');
        openRoot();
    }

    function debugOpen(payload) {
        payload = payload || {};
        log('debugOpen() called', JSON.stringify(payload));
        safeText(ownerEl, 'NUI Debug', 'pawn-owner');
        if (debugMessage) {
            debugMessage.textContent = payload.message || 'debugOpen received. If you can see this panel, CEF loaded web/app.js and NUI messages are reaching the browser.';
        }
        setView('debug');
        openRoot();
    }

    function closeDialog(sendCallback) {
        if (!root) return error('closeDialog failed: #pawn-root missing');
        if (!isOpen && root.classList.contains('hidden')) return;

        isOpen = false;
        currentView = 'dialog';
        root.classList.add('closing');
        root.setAttribute('aria-hidden', 'true');

        window.setTimeout(function () {
            root.classList.remove('visible', 'closing');
            root.style.display = '';
            root.style.visibility = '';
            root.style.opacity = '';
            root.style.pointerEvents = '';
            root.classList.add('hidden');
            setView('dialog');
            clearMessage();
            if (sellList) sellList.innerHTML = '';
            showSellStatus('');
            if (window.W2FStorefront && typeof W2FStorefront.reset === 'function') W2FStorefront.reset();
        }, 180);

        if (sendCallback) post('closeDialog', {});
    }

    function renderSellItem(item) {
        item = item || {};
        var card = document.createElement('div');
        card.className = 'pawn-sell-card' + (item.demanded ? ' pawn-sell-card-demanded' : '');
        var demandBadge = item.demanded ? '<span class="pawn-demand-badge">In demand</span>' : '';
        var loyaltyLine = item.loyaltyBonus > 0
            ? '<span class="pawn-sell-bonus">+' + formatMoney(item.loyaltyBonus) + ' loyalty</span>'
            : '<span class="pawn-sell-bonus pawn-sell-bonus-none">—</span>';
        var demandLine = item.demandBonus > 0
            ? '<span class="pawn-sell-bonus pawn-sell-bonus-demand">+' + formatMoney(item.demandBonus) + ' demand</span>'
            : '<span class="pawn-sell-bonus pawn-sell-bonus-none">—</span>';

        card.innerHTML = '<div class="pawn-sell-card-top">' +
            '<img class="pawn-sell-img" src="' + escapeHtml(item.image || '') + '" alt="" />' +
            '<div class="pawn-sell-meta"><span class="pawn-sell-name">' + escapeHtml(item.label || item.name || 'Unknown item') + ' ' + demandBadge + '</span>' +
            '<span class="pawn-sell-owned">You have: <strong>' + escapeHtml(item.owned || 0) + '</strong></span></div></div>' +
            '<div class="pawn-sell-prices">' +
            '<div class="pawn-sell-price-row"><span>Base</span><span>' + formatMoney(item.baseSellPrice) + '</span></div>' +
            '<div class="pawn-sell-price-row"><span>Loyalty</span>' + loyaltyLine + '</div>' +
            '<div class="pawn-sell-price-row"><span>Demand</span>' + demandLine + '</div>' +
            '<div class="pawn-sell-price-row pawn-sell-price-final"><span>Offer</span><span>' + formatMoney(item.finalSellPrice) + ' each</span></div>' +
            '</div><div class="pawn-sell-actions">' +
            '<button type="button" class="pawn-sell-btn" data-sell="1" data-item="' + escapeHtml(item.name || '') + '">Sell 1</button>' +
            '<button type="button" class="pawn-sell-btn pawn-sell-btn-alt" data-sell="all" data-item="' + escapeHtml(item.name || '') + '">Sell All</button>' +
            '</div>';
        return card;
    }

    function renderSellMenu(payload) {
        payload = payload || {};
        if (!sellList) return error('renderSellMenu failed: #pawn-sell-list missing');
        sellList.innerHTML = '';
        var items = payload.items || [];

        if (!payload.ok) {
            showSellStatus(ERROR_MESSAGES[payload.error] || ERROR_MESSAGES.unknown, true);
            if (sellEmpty) hide(sellEmpty, 'pawn-sell-empty');
            return;
        }
        if (items.length === 0) {
            if (sellEmpty) show(sellEmpty, 'pawn-sell-empty');
            return;
        }
        if (sellEmpty) hide(sellEmpty, 'pawn-sell-empty');
        items.forEach(function (item) { sellList.appendChild(renderSellItem(item)); });
    }

    function openSellMenu(payload) {
        setView('sell');
        openRoot();
        showSellStatus('');
        applySellLoyalty(payload || {});
        renderSellMenu(payload || {});
    }

    function updateSellMenu(payload) {
        payload = payload || {};
        if (payload.sold) {
            var xp = payload.sold.loyaltyXp ? (' +' + payload.sold.loyaltyXp + ' XP') : '';
            showSellStatus('Sold ' + payload.sold.amount + ' for ' + formatMoney(payload.sold.totalPrice) + xp + '.', false);
        }
        if (payload.loyalty) applySellLoyalty(payload);
        renderSellMenu(payload);
    }

    function openRejection(payload) {
        payload = payload || {};
        safeText(byId('pawn-rejection-title', false), payload.title || 'Access Denied', 'pawn-rejection-title');
        safeText(byId('pawn-rejection-msg', false), payload.message || '', 'pawn-rejection-msg');
        safeText(ownerEl, payload.title || 'Dealer', 'pawn-owner');
        setView('rejection');
        openRoot();
    }

    function openStorefront(payload) {
        payload = payload || {};
        var view = payload.theme === 'blackmarket' ? 'blackmarket' : 'storefront';
        if (payload.dealerName) safeText(ownerEl, payload.dealerName, 'pawn-owner');
        if (payload.greeting && view === 'blackmarket') showMessage(payload.greeting);
        setView(view);
        openRoot();
        if (window.W2FStorefront && typeof W2FStorefront.open === 'function') W2FStorefront.open(payload);
        else error('W2FStorefront.open missing; storefront.js may not have loaded');
    }

    function updateStorefront(payload) {
        if (window.W2FStorefront && typeof W2FStorefront.update === 'function') W2FStorefront.update(payload || {});
        else error('W2FStorefront.update missing; storefront.js may not have loaded');
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

    function bindClick(el, name, fn) {
        if (!el) {
            error('Cannot bind click handler; missing element:', name);
            return;
        }
        el.addEventListener('click', fn);
    }

    bindClick(optionsEl, 'pawn-options', function (e) {
        var btn = e.target.closest && e.target.closest('[data-choice]');
        if (!btn) return;
        onChoice(btn.getAttribute('data-choice'));
    });

    bindClick(sellBackBtn, 'pawn-sell-back', function () { post('sellBack', {}); });
    bindClick(storeBackBtn, 'pawn-store-back', function () { post('storefrontBack', {}); });

    bindClick(sellList, 'pawn-sell-list', function (e) {
        var btn = e.target.closest && e.target.closest('[data-sell]');
        if (!btn) return;
        post('sellItem', {
            item: btn.getAttribute('data-item'),
            amount: btn.getAttribute('data-sell') === 'all' ? 'all' : 1
        });
    });

    bindClick(checkoutBtn, 'pawn-checkout-btn', function () {
        if (uiBusy || !window.W2FStorefront || W2FStorefront.viewOnly) return;
        post('checkout', {
            cart: W2FStorefront.getCartPayload ? W2FStorefront.getCartPayload() : [],
            shop: W2FStorefront.getShop ? W2FStorefront.getShop() : 'pawnshop'
        });
    });

    if (rejectionClose) bindClick(rejectionClose, 'pawn-rejection-close', function () { post('rejectionClose', {}); });

    Array.prototype.forEach.call(qsa('[data-close]'), function (el) {
        el.addEventListener('click', function () { closeDialog(true); });
    });

    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape' || !isOpen) return;
        e.preventDefault();
        post('escape', {});
    });

    window.addEventListener('message', function (event) {
        var data = event.data || {};
        log('browser message event received', JSON.stringify(data));
        switch (data.action) {
            case 'setBusy': setBusy(data.busy); break;
            case 'openDialog': openDialog(data); break;
            case 'debugOpen': debugOpen(data); break;
            case 'closeDialog': closeDialog(false); break;
            case 'showMessage': showMessage(data.message); break;
            case 'openRejection': openRejection(data); break;
            case 'openSellMenu': openSellMenu(data); break;
            case 'updateSellMenu': updateSellMenu(data); break;
            case 'sellError': showSellStatus(ERROR_MESSAGES[data.error] || ERROR_MESSAGES.unknown, true); break;
            case 'openStorefront': openStorefront(data); break;
            case 'updateStorefront': updateStorefront(data); break;
            case 'storefrontError':
                var msg = ERROR_MESSAGES[data.error] || ERROR_MESSAGES.unknown;
                if (data.item) msg += ' (' + data.item + ')';
                var status = byId('pawn-store-status', false);
                if (status) {
                    status.textContent = msg;
                    show(status, 'pawn-store-status');
                    addClass(status, 'pawn-store-status-error', 'pawn-store-status');
                } else {
                    error('storefrontError cannot render: #pawn-store-status missing', msg);
                }
                break;
            default:
                warn('Unhandled NUI action:', data.action, data);
                break;
        }
    });

    log('web/app.js loaded; resource=' + RESOURCE);
})();
