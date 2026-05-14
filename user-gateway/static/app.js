const API_PREFIX = "./api/v1";
let token = localStorage.getItem("toolmarket_token");
let currentUser = null;
let products = [];
let categories = [];
let cart = [];
let orders = [];
let selectedProductId = null;
let currentCurrency = localStorage.getItem("toolmarket_currency") || "RUB";
let productPage = 0;
const PRODUCTS_PER_PAGE = 12;
let productHasMore = false;
let isLoadingProducts = false;
const SCROLL_LOAD_THRESHOLD = 300;
let currentTheme = localStorage.getItem("toolmarket_theme") || "dark";

const elements = {
  authSection: document.getElementById("authSection"),
  appSection: document.getElementById("appSection"),
  loginForm: document.getElementById("loginForm"),
  loginFormElement: document.getElementById("loginFormElement"),
  loginError: document.getElementById("loginError"),
  registerForm: document.getElementById("registerForm"),
  registerFormElement: document.getElementById("registerFormElement"),
  registerError: document.getElementById("registerError"),
  switchToRegister: document.getElementById("switchToRegister"),
  switchToLogin: document.getElementById("switchToLogin"),
  loginUsername: document.getElementById("loginUsername"),
  loginPassword: document.getElementById("loginPassword"),
  regUsername: document.getElementById("regUsername"),
  regPassword: document.getElementById("regPassword"),
  logoutBtn: document.getElementById("logoutBtn"),
  accountBtn: document.getElementById("accountBtn"),
  cartBtn: document.getElementById("cartBtn"),
  marketBtn: document.getElementById("marketBtn"),
  userGreeting: document.getElementById("userGreeting"),
  brandLink: document.getElementById("brandLink"),
  cartCount: document.getElementById("cartCount"),
  themeToggleBtn: document.getElementById("themeToggleBtn"),
  
  tabPanels: document.querySelectorAll(".tab-panel"),
  
  productsTab: document.getElementById("productsTab"),
  productsGrid: document.getElementById("productsGrid"),
  productCategoryFilter: document.getElementById("productCategoryFilter"),
  productSearch: document.getElementById("productSearch"),
  productSearchBtn: document.getElementById("productSearchBtn"),
  productResetFilters: document.getElementById("productResetFilters"),
  
  accountTab: document.getElementById("accountTab"),
  accountForm: document.getElementById("accountForm"),
  accountUsername: document.getElementById("accountUsername"),
  accountLanguage: document.getElementById("accountLanguage"),
  accountCurrency: document.getElementById("accountCurrency"),
  accountShipment: document.getElementById("accountShipment"),
  accountPayment: document.getElementById("accountPayment"),
  accountError: document.getElementById("accountError"),
  accountSuccess: document.getElementById("accountSuccess"),
  
  cartTab: document.getElementById("cartTab"),
  cartTable: document.getElementById("cartTable"),
  cartTableContainer: document.getElementById("cartTableContainer"),
  cartEmpty: document.getElementById("cartEmpty"),
  cartTotal: document.getElementById("cartTotal"),
  cartTotalAmount: document.getElementById("cartTotalAmount"),
  cartTotalCurrency: document.getElementById("cartTotalCurrency"),
  clearCartBtn: document.getElementById("clearCartBtn"),
  checkoutBtn: document.getElementById("checkoutBtn"),
  
  ordersTab: document.getElementById("ordersTab"),
  ordersList: document.getElementById("ordersList"),
  ordersEmpty: document.getElementById("ordersEmpty"),
  refreshOrders: document.getElementById("refreshOrders"),
  
  productModal: document.getElementById("productModal"),
  closeProductModal: document.getElementById("closeProductModal"),
  modalProductName: document.getElementById("modalProductName"),
  modalProductPrice: document.getElementById("modalProductPrice"),
  modalProductDescription: document.getElementById("modalProductDescription"),
  modalProductAttributes: document.getElementById("modalProductAttributes"),
  productImages: document.getElementById("productImages"),
  productQuantity: document.getElementById("productQuantity"),
  addToCartBtn: document.getElementById("addToCartBtn"),
  reviewsList: document.getElementById("reviewsList"),
  
  checkoutModal: document.getElementById("checkoutModal"),
  closeCheckoutModal: document.getElementById("closeCheckoutModal"),
  cancelCheckoutBtn: document.getElementById("cancelCheckoutBtn"),
  checkoutForm: document.getElementById("checkoutForm"),
  checkoutShippingAddress: document.getElementById("checkoutShippingAddress"),
  checkoutBillingAddress: document.getElementById("checkoutBillingAddress"),
  checkoutShipment: document.getElementById("checkoutShipment"),
  checkoutError: document.getElementById("checkoutError"),
  addNewAddressBtn: document.getElementById("addNewAddressBtn"),
  
  addressModal: document.getElementById("addressModal"),
  closeAddressModal: document.getElementById("closeAddressModal"),
  addressForm: document.getElementById("addressForm"),
  cancelAddressBtn: document.getElementById("cancelAddressBtn"),
  addressError: document.getElementById("addressError"),
  
  paymentModal: document.getElementById("paymentModal"),
  closePaymentModal: document.getElementById("closePaymentModal"),
  paymentInfo: document.getElementById("paymentInfo"),
  paymentForm: document.getElementById("paymentForm"),
  paymentAmount: document.getElementById("paymentAmount"),
  paymentMethod: document.getElementById("paymentMethod"),
  paymentError: document.getElementById("paymentError"),
  paymentSuccess: document.getElementById("paymentSuccess"),
  cancelPaymentBtn: document.getElementById("cancelPaymentBtn"),
};

function showLogin() {
  elements.authSection.hidden = false;
  elements.appSection.hidden = true;
  elements.logoutBtn.hidden = true;
  elements.accountBtn.hidden = true;
  elements.cartBtn.hidden = true;
  elements.marketBtn.hidden = true;
  elements.userGreeting.hidden = true;
  elements.loginForm.hidden = false;
  elements.registerForm.hidden = true;
}

function showApp() {
  elements.authSection.hidden = true;
  elements.appSection.hidden = false;
  elements.logoutBtn.hidden = false;
  elements.accountBtn.hidden = false;
  elements.cartBtn.hidden = false;
  elements.marketBtn.hidden = false;
  elements.userGreeting.hidden = false;
  if (currentUser) {
    elements.userGreeting.textContent = `Привет, ${currentUser.username}!`;
  }
  updateCartCount();
}

function getAuthHeaders(isForm = false, options = {}) {
  const headers = {};
  if (!isForm && options.method !== "GET" && options.body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

function applyTheme() {
  document.documentElement.dataset.theme = currentTheme;
  if (elements.themeToggleBtn) {
    elements.themeToggleBtn.textContent = currentTheme === "light" ? "Тёмная тема" : "Светлая тема";
  }
}

function toggleTheme() {
  currentTheme = currentTheme === "light" ? "dark" : "light";
  localStorage.setItem("toolmarket_theme", currentTheme);
  applyTheme();
}

async function request(path, options = {}) {
  const isForm = options.body instanceof FormData;
  const headers = { ...(options.headers || {}), ...getAuthHeaders(isForm, options) };
  const response = await fetch(`${API_PREFIX}/${path}`, {
    ...options,
    headers,
  });

  const text = await response.text();
  let payload = null;
  try {
    payload = text ? JSON.parse(text) : null;
  } catch {
    payload = text;
  }

  if (!response.ok) {
    if (response.status === 401) {
      logout();
      throw new Error("Требуется повторная авторизация");
    }
    throw new Error(payload?.detail || payload || response.statusText);
  }
  return payload;
}

function showMessage(target, message) {
  target.textContent = message;
}

function clearMessage(target) {
  target.textContent = "";
}

function setActiveTab(tabName) {
  elements.tabPanels.forEach((panel) => {
    panel.hidden = panel.id !== `${tabName}Tab`;
  });
}

function showPanels(panelNames = []) {
  elements.tabPanels.forEach((panel) => {
    panel.hidden = true;
  });
  panelNames.forEach((name) => {
    const panel = elements[`${name}Tab`];
    if (panel) {
      panel.hidden = false;
    }
  });
}

async function login(username, password) {
  try {
    const response = await request("auth/login", {
      method: "POST",
      body: JSON.stringify({ username, password }),
    });
    token = response.access_token;
    localStorage.setItem("toolmarket_token", token);
    await loadCurrentUser();
    showApp();
    setActiveTab("products");
  } catch (error) {
    showMessage(elements.loginError, error.message);
  }
}

async function register(username, password) {
  try {
    await request("auth/register", {
      method: "POST",
      body: JSON.stringify({
        username,
        password,
      }),
    });
    switchToLogin();
    showMessage(elements.loginError, "Регистрация успешна! Пожалуйста, войдите в систему.");
    setTimeout(() => clearMessage(elements.loginError), 3000);
  } catch (error) {
    showMessage(elements.registerError, error.message);
  }
}

function logout() {
  token = null;
  currentUser = null;
  localStorage.removeItem("toolmarket_token");
  showLogin();
  switchToLogin();
  clearMessage(elements.loginError);
  clearMessage(elements.registerError);
}

async function loadCurrentUser() {
  try {
    currentUser = await request("auth/me", { method: "GET" });
    if (currentUser.role === "employee") {
      logout();
      throw new Error("Сотрудникам доступ запрещён");
    }
    elements.accountLanguage.value = currentUser.preferred_language || "ru";
    elements.accountCurrency.value = currentUser.preferred_currency || "RUB";
    elements.accountShipment.value = currentUser.preferred_shipment_method || "standard";
    elements.accountPayment.value = currentUser.preferred_payment_method || "card";
  } catch (error) {
    console.warn("Не удалось загрузить данные пользователя", error);
    if (error.message === "Сотрудникам доступ запрещён") {
      showMessage(elements.loginError, error.message);
    }
  }
}

async function loadCurrencies() {
  try {
    const response = await request("public/currencies", { method: "GET" });
    const currencies = Array.isArray(response) ? response : [];
    
    elements.accountCurrency.innerHTML = "";
    
    currencies.forEach((currency) => {
      const option = document.createElement("option");
      option.value = currency.code;
      option.textContent = `${currency.code} - ${currency.name}`;
      elements.accountCurrency.appendChild(option);
    });
  } catch (error) {
    console.error("Ошибка при загрузке валют", error);
  }
}

async function loadProducts(page = 0, append = false) {
  if (isLoadingProducts) return;
  isLoadingProducts = true;
  try {
    const search = elements.productSearch.value.trim();
    const category = elements.productCategoryFilter.value;
    const query = `public/products?limit=${PRODUCTS_PER_PAGE}&offset=${page * PRODUCTS_PER_PAGE}${search ? `&search=${encodeURIComponent(search)}` : ""}${category ? `&category_id=${category}` : ""}`;
    const response = await request(query, { method: "GET" });
    const responseProducts = Array.isArray(response) ? response : [];
    const existingIds = new Set(products.map(p => p.product_id));
    const uniqueNewProducts = responseProducts.filter(p => !existingIds.has(p.product_id));
    productHasMore = uniqueNewProducts.length === PRODUCTS_PER_PAGE;
    if (append) {
      products = products.concat(uniqueNewProducts);
      productPage = page;
    } else {
      products = uniqueNewProducts;
      productPage = page;
    }
    await renderProducts(append);
    if (!productHasMore) {
      const endMessage = document.createElement('div');
      endMessage.className = 'end-message';
      endMessage.textContent = 'Вы долистали до конца :)';
      elements.productsGrid.appendChild(endMessage);
    }
  } catch (error) {
    console.error("Ошибка при загрузке товаров", error);
  } finally {
    isLoadingProducts = false;
    // Check if we need to load more after rendering completes
    if (productHasMore) {
      const scrollThreshold = document.body.offsetHeight - window.innerHeight - SCROLL_LOAD_THRESHOLD;
      if (window.scrollY >= scrollThreshold) {
        await loadProducts(productPage + 1, true);
      }
    }
  }
}

async function getProductCardImage(productId) {
  try {
    const images = await request(`public/products/${productId}/images`, { method: "GET" });
    return Array.isArray(images) && images.length > 0 ? images[0].image_url : null;
  } catch {
    return null;
  }
}

async function renderProducts(append = false) {
  if (!append) {
    elements.productsGrid.innerHTML = "";
  }
  
  const startIndex = append ? elements.productsGrid.children.length : 0;
  const productsToRender = products.slice(startIndex);
  
  if (productsToRender.length === 0) return;
  
  // Fetch all images in parallel
  const imageUrls = await Promise.all(
    productsToRender.map((product) => getProductCardImage(product.product_id))
  );
  
  // Render all products together
  productsToRender.forEach((product, index) => {
    const imageUrl = imageUrls[index];
    const card = document.createElement("div");
    card.className = "product-card";
    card.innerHTML = `
      <div class="product-image-container">
        ${imageUrl ? `<img src="${imageUrl}" alt="${product.name}" class="product-image" loading="lazy" />` : `<div class="product-image-placeholder">Нет изображения</div>`}
      </div>
      <h3>${product.name}</h3>
      <p class="product-sku">SKU: ${product.sku}</p>
      <p class="product-price">${product.base_price} RUB</p>
      <p class="product-stock">Кол-во: ${product.stock}</p>
      <button class="primary-button add-to-cart-btn" data-id="${product.product_id}">Добавить в корзину</button>
    `;
    card.querySelector("h3").title = product.name;
    card.querySelector(".product-sku").title = `SKU: ${product.sku}`;
    card.addEventListener("click", () => showProductModal(product.product_id));
    const addBtn = card.querySelector(".add-to-cart-btn");
    if (addBtn) {
      addBtn.addEventListener("click", async (e) => {
        e.stopPropagation();
        await addToCart(product.product_id, 1);
      });
    }
    elements.productsGrid.appendChild(card);
  });
}

async function showProductModal(productId) {
  try {
    const product = await request(`public/products/${productId}`, { method: "GET" });
    const images = await request(`public/products/${productId}/images`, { method: "GET" });
    const attributes = await request(`public/products/${productId}/attributes`, { method: "GET" });
    
    selectedProductId = productId;
    
    elements.modalProductName.textContent = product.name;
    elements.modalProductName.title = product.name;
    elements.modalProductPrice.textContent = `${product.base_price} RUB`;
    elements.modalProductDescription.textContent = product.description || "Описание отсутствует";
    elements.productQuantity.value = 1;
    
    // Изображения
    elements.productImages.innerHTML = "";
    if (images && images.length > 0) {
      const mainImg = document.createElement("img");
      mainImg.src = images[0].image_url;
      mainImg.className = "main-image";
      elements.productImages.appendChild(mainImg);
      
      if (images.length > 1) {
        const thumbsContainer = document.createElement("div");
        thumbsContainer.className = "image-thumbnails";
        images.forEach((img) => {
          const thumb = document.createElement("img");
          thumb.src = img.image_url;
          thumb.className = "thumbnail";
          thumb.addEventListener("click", () => {
            mainImg.src = img.image_url;
          });
          thumbsContainer.appendChild(thumb);
        });
        elements.productImages.appendChild(thumbsContainer);
      }
    } else {
      const placeholder = document.createElement("div");
      placeholder.className = "product-image-placeholder";
      placeholder.textContent = "Нет изображения";
      elements.productImages.appendChild(placeholder);
    }
    
    // Атрибуты
    elements.modalProductAttributes.innerHTML = "";
    if (attributes && attributes.length > 0) {
      attributes.forEach((attr) => {
        const attrEl = document.createElement("p");
        attrEl.innerHTML = `<strong>${attr.attr_name}:</strong> ${attr.attr_value}`;
        elements.modalProductAttributes.appendChild(attrEl);
      });
    }
    
    // Отзывы
    const reviews = await request(`public/products/${productId}/reviews`, { method: "GET" });
    elements.reviewsList.innerHTML = "";
    if (reviews && reviews.length > 0) {
      reviews.forEach((review) => {
        const reviewEl = document.createElement("div");
        reviewEl.className = "review-item";
        reviewEl.innerHTML = `
          <div class="review-header">
            <span class="review-rating">★ ${review.rating}/5</span>
            <span class="review-user">Пользователь #${review.user_id}</span>
          </div>
          ${review.comment ? `<p class="review-comment">${review.comment}</p>` : ""}
          <span class="review-helpful">Полезно: ${review.helpful_count}</span>
        `;
        elements.reviewsList.appendChild(reviewEl);
      });
    } else {
      elements.reviewsList.innerHTML = "<p>Отзывов пока нет</p>";
    }
    
    elements.productModal.hidden = false;
  } catch (error) {
    alert("Ошибка при загрузке информации о товаре: " + error.message);
  }
}

async function loadCategories() {
  try {
    const response = await request("public/categories", { method: "GET" });
    categories = response;
    elements.productCategoryFilter.innerHTML = '<option value="">Все категории</option>';
    categories.forEach((cat) => {
      const option = document.createElement("option");
      option.value = cat.category_id;
      option.textContent = cat.name;
      elements.productCategoryFilter.appendChild(option);
    });
  } catch (error) {
    console.error("Ошибка при загрузке категорий", error);
  }
}

async function loadCart() {
  if (!token) return;
  try {
    const response = await request("customer/cart", { method: "GET" });
    cart = response;
    renderCart();
    updateCartCount();
  } catch (error) {
    console.error("Ошибка при загрузке корзины", error);
  }
}

function updateCartCount() {
  elements.cartCount.textContent = cart.length;
}

function renderCart() {
  if (cart.length === 0) {
    elements.cartEmpty.hidden = false;
    elements.cartTableContainer.hidden = true;
    elements.cartTotal.hidden = true;
    elements.checkoutBtn.hidden = true;
  } else {
    elements.cartEmpty.hidden = true;
    elements.cartTableContainer.hidden = false;
    elements.cartTotal.hidden = false;
    elements.checkoutBtn.hidden = false;
    
    elements.cartTable.innerHTML = "";
    let total = 0;
    cart.forEach((item) => {
      let productName = "Неизвестный товар";
      let price = item.base_price || 0;
      
      if (products && Array.isArray(products)) {
        const product = products.find((p) => p.product_id === item.product_id);
        if (product) {
          productName = product.name;
          price = product.base_price || price;
        }
      }
      
      const sum = price * item.quantity;
      total += sum;
      
      const row = document.createElement("tr");
      row.innerHTML = `
        <td>${productName}</td>
        <td>${price} RUB</td>
        <td>
          <input type="number" min="1" value="${item.quantity}" class="cart-quantity" data-product-id="${item.product_id}" />
        </td>
        <td>${sum.toFixed(2)} RUB</td>
        <td>
          <button class="secondary-button cart-remove-btn" data-product-id="${item.product_id}">Удалить</button>
        </td>
      `;
      elements.cartTable.appendChild(row);
    });
    
    elements.cartTotalAmount.textContent = total.toFixed(2);
    elements.cartTotalCurrency.textContent = currentCurrency;
  }
}

async function addToCart(productId, quantity) {
  if (!token) {
    alert("Пожалуйста, авторизуйтесь");
    return;
  }
  try {
    await request("customer/cart/add", {
      method: "POST",
      body: JSON.stringify({ product_id: productId, quantity }),
    });
    await loadCart();
    elements.productModal.hidden = true;
  } catch (error) {
    alert("Ошибка при добавлении в корзину: " + error.message);
  }
}

async function removeFromCart(productId) {
  if (!token) return;
  try {
    await request(`customer/cart/${productId}`, { method: "DELETE" });
    await loadCart();
  } catch (error) {
    alert("Ошибка при удалении из корзины: " + error.message);
  }
}

async function updateCartQuantity(productId, quantity) {
  if (!token) return;
  try {
    await request("customer/cart/update", {
      method: "PUT",
      body: JSON.stringify({ product_id: productId, quantity }),
    });
    await loadCart();
  } catch (error) {
    alert("Ошибка при обновлении корзины: " + error.message);
  }
}

async function clearCart() {
  if (!token || cart.length === 0) return;
  if (!confirm("Вы уверены?")) return;
  
  for (const item of cart) {
    await removeFromCart(item.product_id);
  }
}

async function loadAddresses() {
  if (!token) return;
  try {
    const response = await request("customer/addresses", { method: "GET" });
    elements.checkoutShippingAddress.innerHTML = "";
    elements.checkoutBillingAddress.innerHTML = '<option value="">Использовать адрес доставки</option>';
    
    response.forEach((addr) => {
      const option = document.createElement("option");
      option.value = addr.address_id;
      option.textContent = `${addr.street}, ${addr.city}, ${addr.zip_code}, ${addr.country}`;
      elements.checkoutShippingAddress.appendChild(option.cloneNode(true));
      elements.checkoutBillingAddress.appendChild(option);
    });
  } catch (error) {
    console.error("Ошибка при загрузке адресов", error);
  }
}

function openCheckout() {
  loadAddresses();
  elements.checkoutModal.hidden = false;
}

async function createOrder(shippingAddressId, billingAddressId, shipmentMethod) {
  try {
    const response = await request("customer/orders", {
      method: "POST",
      body: JSON.stringify({
        shipping_address_id: shippingAddressId,
        billing_address_id: billingAddressId || shippingAddressId,
        shipment_method: shipmentMethod,
      }),
    });
    return response;
  } catch (error) {
    throw error;
  }
}

async function createPayment(orderId, amount) {
  try {
    const response = await request("customer/payments", {
      method: "POST",
      body: JSON.stringify({
        order_id: orderId,
        amount,
        method: elements.paymentMethod.value,
      }),
    });
    return response;
  } catch (error) {
    throw error;
  }
}

async function loadOrders() {
  if (!token) return;
  try {
    const response = await request("customer/orders", { method: "GET" });
    orders = response;
    renderOrders();
  } catch (error) {
    console.error("Ошибка при загрузке заказов", error);
  }
}

function renderOrders() {
  elements.ordersList.innerHTML = "";
  if (orders.length === 0) {
    elements.ordersEmpty.hidden = false;
  } else {
    elements.ordersEmpty.hidden = true;
    orders.forEach((order) => {
      const orderEl = document.createElement("div");
      orderEl.className = "order-item";
      const itemsHtml = order.items.map((item) => `<li>Товар #${item.product_id} × ${item.quantity}</li>`).join("");
      orderEl.innerHTML = `
        <div class="order-header">
          <h3>Заказ #${order.order_id}</h3>
          <span class="order-status">Статус: ${order.status}</span>
        </div>
        <div class="order-details">
          <p><strong>Сумма:</strong> ${order.total_amount_in_base} RUB</p>
          <p><strong>Валюта:</strong> ${order.order_currency}</p>
          <p><strong>Дата:</strong> ${new Date(order.created_at).toLocaleString("ru-RU")}</p>
          <p><strong>Способ доставки:</strong> ${order.shipment_method}</p>
          ${order.tracking_number ? `<p><strong>Трек-номер:</strong> ${order.tracking_number}</p>` : ""}
          <p><strong>Товары:</strong></p>
          <ul>${itemsHtml}</ul>
        </div>
      `;
      elements.ordersList.appendChild(orderEl);
    });
  }
}

async function updateAccount() {
  if (!token) return;
  try {
    clearMessage(elements.accountError);
    clearMessage(elements.accountSuccess);
    
    const updateData = {
      username: elements.accountUsername.value,
      preferred_language: elements.accountLanguage.value,
      preferred_currency: elements.accountCurrency.value,
      preferred_payment_method: elements.accountPayment.value,
      preferred_shipment_method: elements.accountShipment.value,
    };
    
    const response = await request("customer/account", {
      method: "PUT",
      body: JSON.stringify(updateData),
    });
    
    currentUser = response;
    elements.userGreeting.textContent = `Привет, ${currentUser.username}!`;
    showMessage(elements.accountSuccess, "Профиль успешно обновлен");
    setTimeout(() => clearMessage(elements.accountSuccess), 3000);
  } catch (error) {
    showMessage(elements.accountError, error.message);
  }
}

async function createAddress(street, city, zip_code, country, is_default) {
  if (!token) return;
  try {
    await request("customer/addresses", {
      method: "POST",
      body: JSON.stringify({ street, city, zip_code, country, is_default }),
    });
    elements.addressModal.hidden = true;
    clearMessage(elements.addressError);
    document.getElementById("addressForm").reset();
    await loadAddresses();
  } catch (error) {
    showMessage(elements.addressError, error.message);
  }
}

function setupEventListeners() {
  // Переключение форм авторизации
  elements.switchToRegister.addEventListener("click", () => {
    elements.loginForm.hidden = true;
    elements.registerForm.hidden = false;
  });
  
  elements.switchToLogin.addEventListener("click", () => {
    elements.loginForm.hidden = false;
    elements.registerForm.hidden = true;
  });
  
  // Авторизация
  elements.loginFormElement.addEventListener("submit", (e) => {
    e.preventDefault();
    login(elements.loginUsername.value, elements.loginPassword.value);
  });
  
  // Регистрация
  elements.registerFormElement.addEventListener("submit", (e) => {
    e.preventDefault();
    register(
      elements.regUsername.value,
      elements.regPassword.value
    );
  });
  
  // Выход
  elements.logoutBtn.addEventListener("click", logout);
  
  // Профиль
  elements.accountBtn.addEventListener("click", async () => {
    if (currentUser) {
      elements.accountUsername.value = currentUser.username;
      elements.accountLanguage.value = currentUser.preferred_language || "ru";
      elements.accountCurrency.value = currentUser.preferred_currency || "RUB";
      elements.accountShipment.value = currentUser.preferred_shipment_method || "standard";
      elements.accountPayment.value = currentUser.preferred_payment_method || "card";
      clearMessage(elements.accountError);
      clearMessage(elements.accountSuccess);
    }
    await loadOrders();
    showPanels(["account", "orders"]);
  });
  
  elements.accountForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    await updateAccount();
  });
  
  // Корзина
  elements.cartBtn.addEventListener("click", async () => {
    await loadCart();
    showPanels(["cart"]);
  });
  
  elements.cartTable.addEventListener("change", (e) => {
    if (e.target.classList.contains("cart-quantity")) {
      const productId = parseInt(e.target.dataset.productId);
      const quantity = parseInt(e.target.value);
      if (quantity > 0) {
        updateCartQuantity(productId, quantity);
      }
    }
  });
  
  elements.cartTable.addEventListener("click", (e) => {
    if (e.target.classList.contains("cart-remove-btn")) {
      const productId = parseInt(e.target.dataset.productId);
      removeFromCart(productId);
    }
  });
  
  elements.clearCartBtn.addEventListener("click", clearCart);
  
  // Товары
  elements.productSearchBtn.addEventListener("click", () => {
    productPage = 0;
    productHasMore = true;
    loadProducts(0, false);
  });
  
  elements.productSearch.addEventListener("keyup", (e) => {
    if (e.key === "Enter") {
      productPage = 0;
      productHasMore = true;
      loadProducts(0, false);
    }
  });
  
  elements.productCategoryFilter.addEventListener("change", () => {
    productPage = 0;
    productHasMore = true;
    loadProducts(0, false);
  });
  
  elements.productResetFilters.addEventListener("click", () => {
    elements.productSearch.value = "";
    elements.productCategoryFilter.value = "";
    productPage = 0;
    productHasMore = true;
    loadProducts(0, false);
  });
  
  window.addEventListener("scroll", async () => {
    if (!productHasMore || isLoadingProducts) return;
    const scrollThreshold = document.body.offsetHeight - window.innerHeight - SCROLL_LOAD_THRESHOLD;
    if (window.scrollY >= scrollThreshold) {
      await loadProducts(productPage + 1, true);
    }
  });
  
  // Тема
  elements.themeToggleBtn.addEventListener("click", toggleTheme);
  
  // Бренд возвращает к товарам
  if (elements.brandLink) {
    elements.brandLink.addEventListener("click", () => {
      showPanels(["products"]);
    });
  }

  // Маркет кнопка возвращает к товарам
  if (elements.marketBtn) {
    elements.marketBtn.addEventListener("click", () => {
      showPanels(["products"]);
    });
  }

  // Товар
  elements.closeProductModal.addEventListener("click", () => {
    elements.productModal.hidden = true;
  });
  elements.productModal.addEventListener("click", (event) => {
    if (event.target === elements.productModal) {
      elements.productModal.hidden = true;
    }
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !elements.productModal.hidden) {
      elements.productModal.hidden = true;
    }
  });
  
  elements.addToCartBtn.addEventListener("click", async () => {
    if (selectedProductId) {
      await addToCart(selectedProductId, parseInt(elements.productQuantity.value));
    }
  });
  
  // Оформление заказа
  elements.checkoutBtn.addEventListener("click", openCheckout);
  
  elements.closeCheckoutModal.addEventListener("click", () => {
    elements.checkoutModal.hidden = true;
  });
  
  elements.cancelCheckoutBtn.addEventListener("click", () => {
    elements.checkoutModal.hidden = true;
  });
  
  elements.addNewAddressBtn.addEventListener("click", () => {
    elements.addressModal.hidden = false;
  });
  
  elements.checkoutForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    clearMessage(elements.checkoutError);
    
    try {
      const shippingAddressId = parseInt(elements.checkoutShippingAddress.value);
      const billingAddressId = elements.checkoutBillingAddress.value ? parseInt(elements.checkoutBillingAddress.value) : shippingAddressId;
      const shipmentMethod = elements.checkoutShipment.value;
      
      const order = await createOrder(shippingAddressId, billingAddressId, shipmentMethod);
      
      elements.checkoutModal.hidden = true;
      
      // Показать модаль оплаты
      elements.paymentAmount.value = order.total_amount_in_base;
      elements.paymentInfo.innerHTML = `<p>Заказ #${order.order_id} на сумму ${order.total_amount_in_base} ${order.order_currency}</p>`;
      elements.paymentModal.hidden = false;
      elements.paymentModal.dataset.orderId = order.order_id;
    } catch (error) {
      showMessage(elements.checkoutError, error.message);
    }
  });
  
  // Адрес
  elements.closeAddressModal.addEventListener("click", () => {
    elements.addressModal.hidden = true;
  });
  
  elements.cancelAddressBtn.addEventListener("click", () => {
    elements.addressModal.hidden = true;
  });
  
  elements.addressForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    clearMessage(elements.addressError);
    try {
      await createAddress(
        document.getElementById("addressStreet").value,
        document.getElementById("addressCity").value,
        document.getElementById("addressZip").value,
        document.getElementById("addressCountry").value,
        document.getElementById("addressDefault").checked
      );
    } catch (error) {
      showMessage(elements.addressError, error.message);
    }
  });
  
  // Оплата
  elements.closePaymentModal.addEventListener("click", () => {
    elements.paymentModal.hidden = true;
  });
  
  elements.cancelPaymentBtn.addEventListener("click", () => {
    elements.paymentModal.hidden = true;
  });
  
  elements.paymentForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    clearMessage(elements.paymentError);
    clearMessage(elements.paymentSuccess);
    
    try {
      const orderId = parseInt(elements.paymentModal.dataset.orderId);
      const amount = parseFloat(elements.paymentAmount.value);
      
      await createPayment(orderId, amount);
      
      showMessage(elements.paymentSuccess, "Оплата успешно произведена!");
      setTimeout(() => {
        elements.paymentModal.hidden = true;
        cart = [];
        updateCartCount();
        loadOrders();
        setActiveTab("orders");
      }, 2000);
    } catch (error) {
      showMessage(elements.paymentError, error.message);
    }
  });
  
  // Заказы
  elements.refreshOrders.addEventListener("click", loadOrders);
}

async function init() {
  applyTheme();
  setupEventListeners();
  
  try {
    await loadCategories();
    if (token) {
      await loadCurrencies();
    }
  } catch (error) {
    console.error("Ошибка при инициализации", error);
  }
  
  if (token) {
    await loadCurrentUser();
    showApp();
    await loadCart();
    showPanels(["products"]);
  } else {
    showLogin();
  }
  
  await loadProducts(0, false);
}

document.addEventListener("DOMContentLoaded", init);

