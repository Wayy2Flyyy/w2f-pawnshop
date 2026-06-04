(function () {
    'use strict';

    var DEBUG_PREFIX = '[w2f-pawnshop][storefront]';

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

    function toggleClass(el, className, state, name) {
        if (!el) {
            error('Cannot toggle class; missing element:', name || className);
            return false;
        }
        el.classList.toggle(className, !!state);
        return true;
    }

    function show(el, name) {
        if (!el) {
            error('Cannot show missing element:', name);
            return false;
        }
        el.classList.remove('hidden');
        return true;
    }

    function hide(el, name) {
        if (!el) {
            error('Cannot hide missing element:', name);
            return false;
        }
        el.classList.add('hidden');
        return true;
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    window.W2FStorefront = {
        viewOnly: false,
        theme: 'pawnshop',
        items: [],
        cart: {},
        cartMax: 25,
        playerMoney: 0,
        loyalty: null
    };

    function grid() { return byId('pawn-store-grid'); }
    function emptyEl() { return byId('pawn-store-empty'); }
    function statusEl() { return byId('pawn-store-status'); }
    function cartPanel() { return byId('pawn-cart-panel'); }
    function cartItemsEl() { return byId('pawn-cart-items'); }
    function cartEmptyEl() { return byId('pawn-cart-empty'); }
    function subtotalEl() { return byId('pawn-cart-subtotal'); }
    function checkoutBtn() { return byId('pawn-checkout-btn'); }
    function balanceEl() { return byId('pawn-store-balance'); }
    function titleEl() { return byId('pawn-store-title'); }

    function formatMoney(value) {
        return '$' + Number(value || 0).toLocaleString('en-US');
    }

    function findItem(name) {
        return (W2FStorefront.items || []).find(function (i) { return i.name === name; });
    }

    function getCartLines() {
        return Object.keys(W2FStorefront.cart || {}).map(function (name) {
            return W2FStorefront.cart[name];
        });
    }

    function getCartQuantityTotal() {
        var total = 0;
        getCartLines().forEach(function (line) { total += line.quantity; });
        return total;
    }

    function getSubtotal() {
        var total = 0;
        getCartLines().forEach(function (line) { total += line.buyPrice * line.quantity; });
        return total;
    }

    function showStatus(text, isError) {
        var el = statusEl();
        if (!el) return false;
        if (!text) {
            hide(el, 'pawn-store-status');
            el.textContent = '';
            return true;
        }
        el.textContent = text;
        show(el, 'pawn-store-status');
        toggleClass(el, 'pawn-store-status-error', !!isError, 'pawn-store-status');
        return true;
    }

    function renderCart() {
        var viewOnly = W2FStorefront.viewOnly;
        var container = cartItemsEl();
        var panel = cartPanel();
        var empty = cartEmptyEl();
        var subtotal = subtotalEl();
        var checkout = checkoutBtn();
        if (!container || !panel || !empty || !subtotal || !checkout) {
            error('renderCart aborted because one or more cart DOM elements are missing');
            return;
        }

        container.innerHTML = '';
        toggleClass(panel, 'pawn-cart-viewonly', viewOnly, 'pawn-cart-panel');

        if (viewOnly) {
            safeText(empty, 'Stock ledger — browse only.', 'pawn-cart-empty');
            show(empty, 'pawn-cart-empty');
            safeText(subtotal, formatMoney(0), 'pawn-cart-subtotal');
            checkout.disabled = true;
            return;
        }

        var lines = getCartLines();
        if (lines.length === 0) {
            show(empty, 'pawn-cart-empty');
            safeText(subtotal, formatMoney(0), 'pawn-cart-subtotal');
            checkout.disabled = true;
            return;
        }

        hide(empty, 'pawn-cart-empty');
        lines.forEach(function (line) {
            var row = document.createElement('div');
            row.className = 'pawn-cart-line';
            row.innerHTML = '<div class="pawn-cart-line-info">' +
                '<span class="pawn-cart-line-name">' + escapeHtml(line.label) + '</span>' +
                '<span class="pawn-cart-line-price">' + formatMoney(line.buyPrice) + ' each</span>' +
                '</div><div class="pawn-cart-line-controls">' +
                '<button type="button" class="pawn-cart-qty" data-cart-qty="-1" data-item="' + escapeHtml(line.name) + '">−</button>' +
                '<span class="pawn-cart-qty-val">' + escapeHtml(line.quantity) + '</span>' +
                '<button type="button" class="pawn-cart-qty" data-cart-qty="1" data-item="' + escapeHtml(line.name) + '">+</button>' +
                '<button type="button" class="pawn-cart-remove" data-cart-remove="' + escapeHtml(line.name) + '">&times;</button>' +
                '</div>';
            container.appendChild(row);
        });

        var total = getSubtotal();
        safeText(subtotal, formatMoney(total), 'pawn-cart-subtotal');
        checkout.disabled = total <= 0 || total > W2FStorefront.playerMoney;
    }

    function addToCart(name) {
        if (W2FStorefront.viewOnly) return;
        var item = findItem(name);
        if (!item || !item.canBuy || item.loyaltyLocked || item.stock <= 0) return;

        var line = W2FStorefront.cart[name];
        var nextQty = (line ? line.quantity : 0) + 1;
        if (nextQty > item.stock) return;
        if (getCartQuantityTotal() + 1 > W2FStorefront.cartMax) {
            showStatus('Cart limit reached for this visit.', true);
            return;
        }

        W2FStorefront.cart[name] = {
            name: item.name,
            label: item.label,
            buyPrice: item.buyPrice,
            quantity: nextQty,
            stock: item.stock
        };
        renderCart();
    }

    function changeCartQty(name, delta) {
        var line = W2FStorefront.cart[name];
        if (!line) return;
        var item = findItem(name);
        var maxStock = item ? item.stock : line.stock;
        var next = line.quantity + delta;

        if (next <= 0) delete W2FStorefront.cart[name];
        else {
            line.quantity = Math.min(next, maxStock);
            if (item) line.stock = item.stock;
        }
        renderCart();
    }

    function buildCartPayload() {
        return getCartLines().map(function (line) {
            return { item: line.name, quantity: line.quantity };
        });
    }

    function renderGrid() {
        var container = grid();
        var empty = emptyEl();
        if (!container || !empty) {
            error('renderGrid aborted because #pawn-store-grid or #pawn-store-empty is missing');
            return;
        }
        container.innerHTML = '';

        var items = W2FStorefront.items || [];
        if (items.length === 0) {
            show(empty, 'pawn-store-empty');
            return;
        }

        hide(empty, 'pawn-store-empty');
        items.forEach(function (item) {
            item = item || {};
            var card = document.createElement('article');
            card.className = 'pawn-store-card';
            if (item.stock <= 0) card.classList.add('pawn-store-card-out');
            if (item.loyaltyLocked) card.classList.add('pawn-store-card-locked');
            if (item.demanded) card.classList.add('pawn-store-card-demanded');

            var addDisabled = W2FStorefront.viewOnly || !item.canBuy || item.stock <= 0 || item.loyaltyLocked;
            var lockLabel = 'Locked';
            if (item.loyaltyLocked) {
                if (item.requiredLoyalty) lockLabel = 'Lv ' + item.requiredLoyalty + '+';
                else if (item.lockReason === 'level') lockLabel = 'Lv ' + item.minLoyaltyToBuy + '+';
                else if (item.lockReason === 'category') lockLabel = 'Locked';
                else lockLabel = 'Lv ' + (item.minLoyaltyToBuy || 1) + '+';
            }

            var demandTag = item.demanded ? '<span class="pawn-demand-badge">Low stock</span>' : '';
            var exclusiveTag = item.exclusive ? '<span class="pawn-demand-badge pawn-exclusive-badge">Inner</span>' : '';
            var priceNote = item.baseBuyPrice && item.baseBuyPrice > item.buyPrice
                ? '<span class="pawn-store-discount">-' + (W2FStorefront.loyalty && W2FStorefront.loyalty.buyDiscountPercent || 0) + '%</span>'
                : '';
            var desc = item.description ? '<p class="pawn-store-desc">' + escapeHtml(item.description) + '</p>' : '';
            var asideHtml;

            if (W2FStorefront.viewOnly) {
                var stockLabel = item.stock > 0 ? ('x' + item.stock) : 'Out';
                var stockClass = item.stock <= 0 ? 'pawn-store-status-chip pawn-store-status-chip-out' : 'pawn-store-status-chip';
                asideHtml = '<span class="' + stockClass + '">' + escapeHtml(stockLabel) + '</span>';
            } else {
                var addLabel = item.loyaltyLocked ? lockLabel : (item.stock <= 0 ? 'Out of stock' : 'Add');
                asideHtml = '<button type="button" class="pawn-store-add" data-add="' + escapeHtml(item.name || '') + '" ' + (addDisabled ? 'disabled' : '') + '>' + escapeHtml(addLabel) + '</button>';
            }

            card.innerHTML = '<div class="pawn-store-card-row">' +
                '<div class="pawn-store-card-thumb"><img src="' + escapeHtml(item.image || '') + '" alt="" class="pawn-store-card-img" />' + demandTag + exclusiveTag + '</div>' +
                '<div class="pawn-store-card-details"><div class="pawn-store-card-head"><span class="pawn-store-card-cat">' + escapeHtml(item.categoryLabel || item.category || 'Item') + '</span></div>' +
                '<h3 class="pawn-store-card-name">' + escapeHtml(item.label || item.name || 'Unknown item') + '</h3>' + desc +
                '<div class="pawn-store-card-foot"><span class="pawn-store-card-stock">Stock <strong>' + escapeHtml(item.stock || 0) + '</strong></span>' +
                '<span class="pawn-store-card-price">' + formatMoney(item.buyPrice) + priceNote + '</span></div></div>' +
                '<div class="pawn-store-card-aside">' + asideHtml + '</div></div>';
            container.appendChild(card);
        });
    }

    function applyLayoutMode() {
        var layoutEl = document.querySelector('.pawn-store-layout');
        if (!layoutEl) {
            warn('Cannot apply storefront layout mode: .pawn-store-layout missing');
            return;
        }
        toggleClass(layoutEl, 'pawn-store-layout-viewonly', W2FStorefront.viewOnly, 'pawn-store-layout');
    }

    window.W2FStorefront.open = function (payload) {
        payload = payload || {};
        log('open() called', JSON.stringify(payload));
        W2FStorefront.viewOnly = !!payload.viewOnly;
        W2FStorefront.theme = payload.theme === 'blackmarket' ? 'blackmarket' : 'pawnshop';
        W2FStorefront.items = payload.items || [];
        W2FStorefront.cart = {};
        W2FStorefront.cartMax = payload.cartMax || 25;
        W2FStorefront.playerMoney = payload.playerMoney || 0;
        W2FStorefront.loyalty = payload.loyalty || null;

        safeText(titleEl(), W2FStorefront.theme === 'blackmarket' ? 'Black Market' : (W2FStorefront.viewOnly ? 'Stock Ledger' : 'Pawnshop Shelves'), 'pawn-store-title');
        var balanceText = W2FStorefront.viewOnly
            ? (W2FStorefront.items.length + ' items · view only')
            : ('Balance: ' + formatMoney(W2FStorefront.playerMoney));
        if (W2FStorefront.loyalty && !W2FStorefront.viewOnly) {
            balanceText += ' · Lv' + W2FStorefront.loyalty.level + ' (-' + W2FStorefront.loyalty.buyDiscountPercent + '%)';
        }
        safeText(balanceEl(), balanceText, 'pawn-store-balance');

        applyLayoutMode();
        showStatus('');
        renderGrid();
        renderCart();
    };

    window.W2FStorefront.update = function (payload) {
        payload = payload || {};
        log('update() called', JSON.stringify(payload));
        W2FStorefront.items = payload.items || [];
        W2FStorefront.playerMoney = payload.playerMoney != null ? payload.playerMoney : W2FStorefront.playerMoney;
        W2FStorefront.loyalty = payload.loyalty || W2FStorefront.loyalty;

        if (!W2FStorefront.viewOnly) safeText(balanceEl(), 'Balance: ' + formatMoney(W2FStorefront.playerMoney), 'pawn-store-balance');

        getCartLines().forEach(function (line) {
            var item = findItem(line.name);
            if (!item || line.quantity > item.stock) {
                if (item) line.quantity = Math.min(line.quantity, item.stock);
                if (!item || item.stock <= 0) delete W2FStorefront.cart[line.name];
            } else {
                line.stock = item.stock;
                line.buyPrice = item.buyPrice;
            }
        });

        if (payload.purchased) {
            W2FStorefront.cart = {};
            showStatus('Paid ' + formatMoney(payload.purchased.totalPaid) + ' — thank you.', false);
        }
        renderGrid();
        renderCart();
    };

    window.W2FStorefront.reset = function () {
        W2FStorefront.cart = {};
        W2FStorefront.items = [];
        showStatus('');
    };

    var storeGrid = byId('pawn-store-grid');
    if (storeGrid) {
        storeGrid.addEventListener('click', function (e) {
            var btn = e.target.closest && e.target.closest('[data-add]');
            if (!btn || btn.disabled) return;
            addToCart(btn.getAttribute('data-add'));
        });
    }

    var cartItems = cartItemsEl();
    if (cartItems) {
        cartItems.addEventListener('click', function (e) {
            var minus = e.target.closest && e.target.closest('[data-cart-qty="-1"]');
            var plus = e.target.closest && e.target.closest('[data-cart-qty="1"]');
            var remove = e.target.closest && e.target.closest('[data-cart-remove]');
            if (minus) changeCartQty(minus.getAttribute('data-item'), -1);
            if (plus) changeCartQty(plus.getAttribute('data-item'), 1);
            if (remove) {
                delete W2FStorefront.cart[remove.getAttribute('data-cart-remove')];
                renderCart();
            }
        });
    }

    window.W2FStorefront.getCartPayload = buildCartPayload;
    window.W2FStorefront.getShop = function () {
        return W2FStorefront.theme === 'blackmarket' ? 'blackmarket' : 'pawnshop';
    };

    log('web/storefront.js loaded');
})();
