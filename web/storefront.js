(function () {
    'use strict';

    window.W2FStorefront = {
        viewOnly: false,
        theme: 'pawnshop',
        items: [],
        cart: {},
        cartMax: 25,
        playerMoney: 0,
    };

    const grid = () => document.getElementById('pawn-store-grid');
    const emptyEl = () => document.getElementById('pawn-store-empty');
    const statusEl = () => document.getElementById('pawn-store-status');
    const cartPanel = () => document.getElementById('pawn-cart-panel');
    const cartItemsEl = () => document.getElementById('pawn-cart-items');
    const cartEmptyEl = () => document.getElementById('pawn-cart-empty');
    const subtotalEl = () => document.getElementById('pawn-cart-subtotal');
    const checkoutBtn = () => document.getElementById('pawn-checkout-btn');
    const balanceEl = () => document.getElementById('pawn-store-balance');
    const titleEl = () => document.getElementById('pawn-store-title');

    function formatMoney(value) {
        return '$' + Number(value || 0).toLocaleString('en-US');
    }

    function findItem(name) {
        return W2FStorefront.items.find(function (i) { return i.name === name; });
    }

    function getCartLines() {
        return Object.keys(W2FStorefront.cart).map(function (name) {
            return W2FStorefront.cart[name];
        });
    }

    function getCartQuantityTotal() {
        var total = 0;
        getCartLines().forEach(function (line) {
            total += line.quantity;
        });
        return total;
    }

    function getSubtotal() {
        var total = 0;
        getCartLines().forEach(function (line) {
            total += line.buyPrice * line.quantity;
        });
        return total;
    }

    function showStatus(text, isError) {
        var el = statusEl();
        if (!text) {
            el.classList.add('hidden');
            el.textContent = '';
            return;
        }
        el.textContent = text;
        el.classList.remove('hidden');
        el.classList.toggle('pawn-store-status-error', !!isError);
    }

    function syncItemStock(name, stock) {
        var item = findItem(name);
        if (item) item.stock = stock;
    }

    function renderCart() {
        var viewOnly = W2FStorefront.viewOnly;
        var container = cartItemsEl();
        container.innerHTML = '';

        cartPanel().classList.toggle('pawn-cart-viewonly', viewOnly);

        if (viewOnly) {
            cartEmptyEl().textContent = 'Stock ledger — browse only.';
            cartEmptyEl().classList.remove('hidden');
            subtotalEl().textContent = formatMoney(0);
            checkoutBtn().disabled = true;
            return;
        }

        var lines = getCartLines();
        if (lines.length === 0) {
            cartEmptyEl().classList.remove('hidden');
            subtotalEl().textContent = formatMoney(0);
            checkoutBtn().disabled = true;
            return;
        }

        cartEmptyEl().classList.add('hidden');

        lines.forEach(function (line) {
            var row = document.createElement('div');
            row.className = 'pawn-cart-line';
            row.innerHTML = `
                <div class="pawn-cart-line-info">
                    <span class="pawn-cart-line-name">${line.label}</span>
                    <span class="pawn-cart-line-price">${formatMoney(line.buyPrice)} each</span>
                </div>
                <div class="pawn-cart-line-controls">
                    <button type="button" class="pawn-cart-qty" data-cart-qty="-1" data-item="${line.name}">−</button>
                    <span class="pawn-cart-qty-val">${line.quantity}</span>
                    <button type="button" class="pawn-cart-qty" data-cart-qty="1" data-item="${line.name}">+</button>
                    <button type="button" class="pawn-cart-remove" data-cart-remove="${line.name}">&times;</button>
                </div>
            `;
            container.appendChild(row);
        });

        var subtotal = getSubtotal();
        subtotalEl().textContent = formatMoney(subtotal);
        checkoutBtn().disabled = subtotal <= 0 || subtotal > W2FStorefront.playerMoney;
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
            stock: item.stock,
        };

        renderCart();
    }

    function changeCartQty(name, delta) {
        var line = W2FStorefront.cart[name];
        if (!line) return;

        var item = findItem(name);
        var maxStock = item ? item.stock : line.stock;
        var next = line.quantity + delta;

        if (next <= 0) {
            delete W2FStorefront.cart[name];
        } else {
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
        container.innerHTML = '';

        var items = W2FStorefront.items || [];
        if (items.length === 0) {
            emptyEl().classList.remove('hidden');
            return;
        }

        emptyEl().classList.add('hidden');

        items.forEach(function (item) {
            var card = document.createElement('article');
            card.className = 'pawn-store-card';
            if (item.stock <= 0) card.classList.add('pawn-store-card-out');
            if (item.loyaltyLocked) card.classList.add('pawn-store-card-locked');
            if (item.demanded) card.classList.add('pawn-store-card-demanded');

            var addDisabled = W2FStorefront.viewOnly || !item.canBuy || item.stock <= 0 || item.loyaltyLocked;
            var lockLabel = 'Locked';
            if (item.loyaltyLocked) {
                if (item.requiredLoyalty) {
                    lockLabel = 'Lv ' + item.requiredLoyalty + '+';
                } else if (item.lockReason === 'level') {
                    lockLabel = 'Lv ' + item.minLoyaltyToBuy + '+';
                } else if (item.lockReason === 'category') {
                    lockLabel = 'Locked';
                } else {
                    lockLabel = 'Lv ' + (item.minLoyaltyToBuy || 1) + '+';
                }
            }

            var demandTag = item.demanded ? '<span class="pawn-demand-badge">Low stock</span>' : '';
            var exclusiveTag = item.exclusive ? '<span class="pawn-demand-badge pawn-exclusive-badge">Inner</span>' : '';
            var priceNote = item.baseBuyPrice && item.baseBuyPrice > item.buyPrice
                ? '<span class="pawn-store-discount">-' + (W2FStorefront.loyalty && W2FStorefront.loyalty.buyDiscountPercent || 0) + '%</span>'
                : '';
            var desc = item.description ? '<p class="pawn-store-desc">' + item.description + '</p>' : '';

            var asideHtml;
            if (W2FStorefront.viewOnly) {
                var stockLabel = item.stock > 0 ? ('x' + item.stock) : 'Out';
                var stockClass = item.stock <= 0 ? 'pawn-store-status-chip pawn-store-status-chip-out' : 'pawn-store-status-chip';
                asideHtml = '<span class="' + stockClass + '">' + stockLabel + '</span>';
            } else {
                var addLabel = item.loyaltyLocked
                    ? lockLabel
                    : (item.stock <= 0 ? 'Out of stock' : 'Add');
                asideHtml = '<button type="button" class="pawn-store-add" data-add="' + item.name + '" '
                    + (addDisabled ? 'disabled' : '') + '>' + addLabel + '</button>';
            }

            card.innerHTML = `
                <div class="pawn-store-card-row">
                    <div class="pawn-store-card-thumb">
                        <img src="${item.image}" alt="" class="pawn-store-card-img" />
                        ${demandTag}${exclusiveTag}
                    </div>
                    <div class="pawn-store-card-details">
                        <div class="pawn-store-card-head">
                            <span class="pawn-store-card-cat">${item.categoryLabel || item.category}</span>
                        </div>
                        <h3 class="pawn-store-card-name">${item.label}</h3>
                        ${desc}
                        <div class="pawn-store-card-foot">
                            <span class="pawn-store-card-stock">Stock <strong>${item.stock}</strong></span>
                            <span class="pawn-store-card-price">${formatMoney(item.buyPrice)}${priceNote}</span>
                        </div>
                    </div>
                    <div class="pawn-store-card-aside">${asideHtml}</div>
                </div>
            `;

            container.appendChild(card);
        });
    }

    function applyLayoutMode() {
        var layoutEl = document.querySelector('.pawn-store-layout');
        if (layoutEl) {
            layoutEl.classList.toggle('pawn-store-layout-viewonly', W2FStorefront.viewOnly);
        }
    }

    window.W2FStorefront.open = function (payload) {
        W2FStorefront.viewOnly = !!payload.viewOnly;
        W2FStorefront.theme = payload.theme === 'blackmarket' ? 'blackmarket' : 'pawnshop';
        W2FStorefront.items = payload.items || [];
        W2FStorefront.cart = {};
        W2FStorefront.cartMax = payload.cartMax || 25;
        W2FStorefront.playerMoney = payload.playerMoney || 0;
        W2FStorefront.loyalty = payload.loyalty || null;

        if (W2FStorefront.theme === 'blackmarket') {
            titleEl().textContent = 'Black Market';
        } else {
            titleEl().textContent = W2FStorefront.viewOnly ? 'Stock Ledger' : 'Pawnshop Shelves';
        }
        var balanceText = W2FStorefront.viewOnly
            ? (W2FStorefront.items.length + ' items · view only')
            : ('Balance: ' + formatMoney(W2FStorefront.playerMoney));
        if (W2FStorefront.loyalty && !W2FStorefront.viewOnly) {
            balanceText += ' · Lv' + W2FStorefront.loyalty.level + ' (-' + W2FStorefront.loyalty.buyDiscountPercent + '%)';
        }
        balanceEl().textContent = balanceText;

        applyLayoutMode();
        showStatus('');
        renderGrid();
        renderCart();
    };

    window.W2FStorefront.update = function (payload) {
        W2FStorefront.items = payload.items || [];
        W2FStorefront.playerMoney = payload.playerMoney != null
            ? payload.playerMoney
            : W2FStorefront.playerMoney;
        W2FStorefront.loyalty = payload.loyalty || W2FStorefront.loyalty;

        if (!W2FStorefront.viewOnly) {
            balanceEl().textContent = 'Balance: ' + formatMoney(W2FStorefront.playerMoney);
        }

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

    document.getElementById('pawn-store-grid').addEventListener('click', function (e) {
        var btn = e.target.closest('[data-add]');
        if (!btn || btn.disabled) return;
        addToCart(btn.getAttribute('data-add'));
    });

    cartItemsEl().addEventListener('click', function (e) {
        var minus = e.target.closest('[data-cart-qty="-1"]');
        var plus = e.target.closest('[data-cart-qty="1"]');
        var remove = e.target.closest('[data-cart-remove]');

        if (minus) changeCartQty(minus.getAttribute('data-item'), -1);
        if (plus) changeCartQty(plus.getAttribute('data-item'), 1);
        if (remove) {
            delete W2FStorefront.cart[remove.getAttribute('data-cart-remove')];
            renderCart();
        }
    });

    window.W2FStorefront.getCartPayload = buildCartPayload;

    window.W2FStorefront.getShop = function () {
        return W2FStorefront.theme === 'blackmarket' ? 'blackmarket' : 'pawnshop';
    };
})();
