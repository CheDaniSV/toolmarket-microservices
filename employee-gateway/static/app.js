const API_PREFIX = "./api/v1";
let token = localStorage.getItem("toolmarket_admin_token");
let products = [];
let categories = [];
let orders = [];
let selectedProductId = null;
let editingCategoryId = null;

const elements = {
  loginSection: document.getElementById("loginSection"),
  appSection: document.getElementById("appSection"),
  logoutBtn: document.getElementById("logoutBtn"),
  loginForm: document.getElementById("loginForm"),
  loginError: document.getElementById("loginError"),
  tabs: document.querySelectorAll(".tab-button"),
  tabPanels: document.querySelectorAll(".tab-panel"),
  refreshProducts: document.getElementById("refreshProducts"),
  refreshCategories: document.getElementById("refreshCategories"),
  refreshOrders: document.getElementById("refreshOrders"),
  orderStatusFilter: document.getElementById("orderStatusFilter"),
  orderSortBy: document.getElementById("orderSortBy"),
  productsTable: document.getElementById("productsTable"),
  categoriesTable: document.getElementById("categoriesTable"),
  ordersTable: document.getElementById("ordersTable"),
  productForm: document.getElementById("productForm"),
  categoryForm: document.getElementById("categoryForm"),
  productCategory: document.getElementById("productCategory"),
  categoryParent: document.getElementById("categoryParent"),
  productDetails: document.getElementById("productDetails"),
  productDetailsPlaceholder: document.getElementById("productDetailsPlaceholder"),
  detailProductId: document.getElementById("detailProductId"),
  detailProductSku: document.getElementById("detailProductSku"),
  detailProductName: document.getElementById("detailProductName"),
  detailProductCategory: document.getElementById("detailProductCategory"),
  detailProductPrice: document.getElementById("detailProductPrice"),
  detailProductStock: document.getElementById("detailProductStock"),
  productAttributesList: document.getElementById("productAttributesList"),
  productImagesList: document.getElementById("productImagesList"),
  attributeForm: document.getElementById("attributeForm"),
  imageForm: document.getElementById("imageForm"),
};

function showLogin() {
  elements.loginSection.hidden = false;
  elements.appSection.hidden = true;
  elements.logoutBtn.hidden = true;
}

function showApp() {
  elements.loginSection.hidden = true;
  elements.appSection.hidden = false;
  elements.logoutBtn.hidden = false;
}

function getAuthHeaders(isForm = false) {
  const headers = {};
  if (!isForm) {
    headers["Content-Type"] = "application/json";
  }
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

async function request(path, options = {}) {
  const isForm = options.body instanceof FormData;
  const headers = { ...(options.headers || {}), ...getAuthHeaders(isForm) };
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
  elements.tabs.forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tabName);
  });
  elements.tabPanels.forEach((panel) => {
    panel.classList.toggle("hidden", panel.id !== `${tabName}Tab`);
  });
}

function resetProductForm() {
  selectedProductId = null;
  document.getElementById("productId").value = "";
  document.getElementById("productSku").value = "";
  document.getElementById("productName").value = "";
  document.getElementById("productDescription").value = "";
  document.getElementById("productPrice").value = "";
  document.getElementById("productStock").value = "0";
  document.getElementById("productCategory").value = "";
  elements.productDetails.hidden = true;
  elements.productDetailsPlaceholder.hidden = false;
  elements.productAttributesList.innerHTML = "";
  elements.productImagesList.innerHTML = "";
}

function resetCategoryForm() {
  editingCategoryId = null;
  document.getElementById("categoryId").value = "";
  document.getElementById("categoryName").value = "";
  document.getElementById("categoryParent").value = "";
}

function getCategoryName(categoryId) {
  const category = categories.find((item) => item.category_id === categoryId);
  return category ? category.name : "-";
}

function formatDate(value) {
  return new Date(value).toLocaleString("ru-RU", { hour12: false });
}

async function login(event) {
  event.preventDefault();
  const username = document.getElementById("username").value.trim();
  const password = document.getElementById("password").value;

  try {
    const data = await request("auth/login", {
      method: "POST",
      body: JSON.stringify({ username, password }),
    });
    token = data.access_token;
    localStorage.setItem("toolmarket_admin_token", token);
    clearMessage(elements.loginError);
    await initializeAdmin();
    showApp();
  } catch (error) {
    showMessage(elements.loginError, error.message);
  }
}

function logout() {
  token = null;
  localStorage.removeItem("toolmarket_admin_token");
  showLogin();
}

async function initializeAdmin() {
  await Promise.all([loadCategories(), loadProducts(), loadOrders()]);
}

async function loadCategories() {
  categories = await request("public/categories");
  elements.categoryParent.innerHTML = `<option value="">Без родителя</option>`;
  elements.productCategory.innerHTML = `<option value="">Без категории</option>`;
  categories.forEach((category) => {
    const option = document.createElement("option");
    option.value = category.category_id;
    option.textContent = category.name;
    elements.categoryParent.appendChild(option);

    const productOption = option.cloneNode(true);
    elements.productCategory.appendChild(productOption);
  });
  renderCategories();
}

async function loadProducts() {
  products = await request("public/products");
  renderProducts();
}

async function loadOrderDetails() {
  const status = elements.orderStatusFilter.value;
  const statusQuery = status ? `?status=${encodeURIComponent(status)}` : "";
  orders = await request(`employee/orders${statusQuery}`);
  renderOrders();
}

async function loadOrders() {
  await loadOrderDetails();
}

function renderProducts() {
  elements.productsTable.innerHTML = "";
  products.forEach((product) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${product.product_id}</td>
      <td>${product.sku}</td>
      <td>${product.name}</td>
      <td>${product.base_price.toFixed(2)}</td>
      <td>${product.stock}</td>
      <td>${getCategoryName(product.category_id)}</td>
      <td class="actions-cell">
        <button data-id="${product.product_id}" class="secondary-button edit-product">Ред.</button>
        <button data-id="${product.product_id}" class="secondary-button delete-product">Удал.</button>
      </td>
    `;
    elements.productsTable.appendChild(row);
  });
}

function renderCategories() {
  elements.categoriesTable.innerHTML = "";
  categories.forEach((category) => {
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${category.category_id}</td>
      <td>${category.name}</td>
      <td>${getCategoryName(category.parent_category_id)}</td>
      <td>
        <button data-id="${category.category_id}" class="secondary-button edit-category">Ред.</button>
        <button data-id="${category.category_id}" class="secondary-button delete-category">Удал.</button>
      </td>
    `;
    elements.categoriesTable.appendChild(row);
  });
}

function renderOrders() {
  const sortBy = elements.orderSortBy.value;
  const sorted = [...orders].sort((a, b) => {
    if (sortBy === "client") {
      return a.user_id - b.user_id;
    }
    if (sortBy === "product") {
      const aItem = a.items[0]?.product_id || 0;
      const bItem = b.items[0]?.product_id || 0;
      return aItem - bItem;
    }
    return new Date(b.created_at) - new Date(a.created_at);
  });

  elements.ordersTable.innerHTML = "";
  sorted.forEach((order) => {
    const itemText = order.items.map((item) => `${item.product_id}×${item.quantity}`).join(", ");
    const row = document.createElement("tr");
    row.innerHTML = `
      <td>${order.order_id}</td>
      <td>${order.user_id}</td>
      <td>${order.status}</td>
      <td>${order.total_amount_in_base.toFixed(2)}</td>
      <td>${formatDate(order.created_at)}</td>
      <td>${itemText || "-"}</td>
      <td>
        <select data-id="${order.order_id}" class="order-status-select">
          <option value="created" ${order.status === "created" ? "selected" : ""}>created</option>
          <option value="payed" ${order.status === "payed" ? "selected" : ""}>payed</option>
          <option value="processing" ${order.status === "processing" ? "selected" : ""}>processing</option>
          <option value="completed" ${order.status === "completed" ? "selected" : ""}>completed</option>
          <option value="cancelled" ${order.status === "cancelled" ? "selected" : ""}>cancelled</option>
        </select>
      </td>
    `;
    elements.ordersTable.appendChild(row);
  });
}

async function selectProduct(productId) {
  const product = products.find((item) => item.product_id === productId);
  if (!product) return;
  selectedProductId = productId;
  document.getElementById("productId").value = product.product_id;
  document.getElementById("productSku").value = product.sku;
  document.getElementById("productName").value = product.name;
  document.getElementById("productDescription").value = product.description || "";
  document.getElementById("productPrice").value = product.base_price;
  document.getElementById("productStock").value = product.stock;
  document.getElementById("productCategory").value = product.category_id || "";

  elements.detailProductId.textContent = product.product_id;
  elements.detailProductSku.textContent = product.sku;
  elements.detailProductName.textContent = product.name;
  elements.detailProductCategory.textContent = getCategoryName(product.category_id);
  elements.detailProductPrice.textContent = product.base_price.toFixed(2);
  elements.detailProductStock.textContent = product.stock;

  elements.productDetailsPlaceholder.hidden = true;
  elements.productDetails.hidden = false;

  await loadProductAttributes(productId);
  await loadProductImages(productId);
}

async function loadProductAttributes(productId) {
  const attributes = await request(`public/products/${productId}/attributes`);
  elements.productAttributesList.innerHTML = "";
  attributes.forEach((attr) => {
    const row = document.createElement("div");
    row.className = "compact-row";
    row.innerHTML = `
      <div><strong>${attr.attr_name}</strong>: ${attr.attr_value}</div>
      <button data-id="${attr.attribute_id}" class="secondary-button delete-attribute">Удалить</button>
    `;
    elements.productAttributesList.appendChild(row);
  });
  if (attributes.length === 0) {
    elements.productAttributesList.textContent = "Нет атрибутов.";
  }
}

async function loadProductImages(productId) {
  try {
    const images = await request(`public/products/${productId}/images`);
    elements.productImagesList.innerHTML = "";
    images.forEach((image) => {
      const row = document.createElement("div");
      row.className = "compact-row";
      row.innerHTML = `
        <div><a href="${image.image_url}" target="_blank">${image.image_url}</a> (#${image.image_order})</div>
        <button data-id="${image.image_id}" class="secondary-button delete-image">Удалить</button>
      `;
      elements.productImagesList.appendChild(row);
    });
    if (images.length === 0) {
      elements.productImagesList.textContent = "Нет изображений.";
    }
  } catch (error) {
    elements.productImagesList.textContent = "Не удалось загрузить изображения.";
  }
}

async function saveProduct(event) {
  event.preventDefault();
  const productId = document.getElementById("productId").value;
  const payload = {
    sku: document.getElementById("productSku").value.trim(),
    name: document.getElementById("productName").value.trim(),
    description: document.getElementById("productDescription").value.trim(),
    base_price: Number(document.getElementById("productPrice").value),
    stock: Number(document.getElementById("productStock").value),
    category_id: document.getElementById("productCategory").value || null,
  };
  try {
    if (productId) {
      await request(`employee/products/${productId}`, {
        method: "PUT",
        body: JSON.stringify(payload),
      });
    } else {
      await request("employee/products", {
        method: "POST",
        body: JSON.stringify(payload),
      });
    }
    await loadProducts();
    resetProductForm();
  } catch (error) {
    alert(error.message);
  }
}

async function removeProduct(productId) {
  if (!confirm("Удалить товар?")) return;
  await request(`employee/products/${productId}`, {
    method: "DELETE",
  });
  await loadProducts();
  resetProductForm();
}

async function saveCategory(event) {
  event.preventDefault();
  const categoryId = document.getElementById("categoryId").value;
  const payload = {
    name: document.getElementById("categoryName").value.trim(),
    parent_category_id: document.getElementById("categoryParent").value || null,
  };
  try {
    if (categoryId) {
      await request(`employee/categories/${categoryId}`, {
        method: "PUT",
        body: JSON.stringify(payload),
      });
    } else {
      await request("employee/categories", {
        method: "POST",
        body: JSON.stringify(payload),
      });
    }
    await loadCategories();
    resetCategoryForm();
  } catch (error) {
    alert(error.message);
  }
}

async function removeCategory(categoryId) {
  if (!confirm("Удалить категорию?")) return;
  await request(`employee/categories/${categoryId}`, {
    method: "DELETE",
  });
  await loadCategories();
}

async function saveAttribute(event) {
  event.preventDefault();
  if (!selectedProductId) {
    alert("Выберите товар.");
    return;
  }
  const attrName = document.getElementById("attributeName").value.trim();
  const attrValue = document.getElementById("attributeValue").value.trim();
  await request(`employee/products/${selectedProductId}/attributes`, {
    method: "POST",
    body: JSON.stringify({ product_id: selectedProductId, attr_name: attrName, attr_value: attrValue }),
  });
  document.getElementById("attributeName").value = "";
  document.getElementById("attributeValue").value = "";
  await loadProductAttributes(selectedProductId);
}

async function deleteAttribute(attributeId) {
  await request(`employee/products/${selectedProductId}/attributes/${attributeId}`, {
    method: "DELETE",
  });
  await loadProductAttributes(selectedProductId);
}

async function saveImage(event) {
  event.preventDefault();
  if (!selectedProductId) {
    alert("Выберите товар.");
    return;
  }
  const fileInput = document.getElementById("imageFile");
  const file = fileInput.files?.[0];
  if (!file) {
    alert("Выберите файл изображения.");
    return;
  }
  const imageOrder = Number(document.getElementById("imageOrder").value || 0);
  const formData = new FormData();
  formData.append("file", file);
  formData.append("image_order", String(imageOrder));
  await request(`employee/products/${selectedProductId}/images`, {
    method: "POST",
    body: formData,
  });
  fileInput.value = "";
  document.getElementById("imageOrder").value = "0";
  await loadProductImages(selectedProductId);
}

async function deleteImage(imageId) {
  await request(`employee/products/${selectedProductId}/images/${imageId}`, {
    method: "DELETE",
  });
  await loadProductImages(selectedProductId);
}

async function changeOrderStatus(orderId, status) {
  await request(`employee/orders/${orderId}/status`, {
    method: "PUT",
    body: JSON.stringify({ status }),
  });
  await loadOrders();
}

function attachDelegatedEvents() {
  document.body.addEventListener("click", async (event) => {
    if (event.target.matches(".edit-product")) {
      const productId = Number(event.target.dataset.id);
      selectProduct(productId);
    }
    if (event.target.matches(".delete-product")) {
      const productId = Number(event.target.dataset.id);
      await removeProduct(productId);
    }
    if (event.target.matches(".edit-category")) {
      const categoryId = Number(event.target.dataset.id);
      const category = categories.find((item) => item.category_id === categoryId);
      if (!category) return;
      editingCategoryId = categoryId;
      document.getElementById("categoryId").value = category.category_id;
      document.getElementById("categoryName").value = category.name;
      document.getElementById("categoryParent").value = category.parent_category_id || "";
    }
    if (event.target.matches(".delete-category")) {
      const categoryId = Number(event.target.dataset.id);
      await removeCategory(categoryId);
    }
    if (event.target.matches(".delete-attribute")) {
      const attributeId = Number(event.target.dataset.id);
      await deleteAttribute(attributeId);
    }
    if (event.target.matches(".delete-image")) {
      const imageId = Number(event.target.dataset.id);
      await deleteImage(imageId);
    }
  });

  document.body.addEventListener("change", async (event) => {
    if (event.target.matches(".order-status-select")) {
      const orderId = Number(event.target.dataset.id);
      await changeOrderStatus(orderId, event.target.value);
    }
  });
}

function setupListeners() {
  elements.loginForm.addEventListener("submit", login);
  elements.logoutBtn.addEventListener("click", logout);
  elements.tabs.forEach((button) => button.addEventListener("click", () => setActiveTab(button.dataset.tab)));
  elements.refreshProducts.addEventListener("click", loadProducts);
  elements.refreshCategories.addEventListener("click", loadCategories);
  elements.refreshOrders.addEventListener("click", loadOrders);
  elements.orderStatusFilter.addEventListener("change", loadOrders);
  elements.orderSortBy.addEventListener("change", renderOrders);
  elements.productForm.addEventListener("submit", saveProduct);
  document.getElementById("resetProduct").addEventListener("click", resetProductForm);
  elements.categoryForm.addEventListener("submit", saveCategory);
  document.getElementById("resetCategory").addEventListener("click", resetCategoryForm);
  elements.attributeForm.addEventListener("submit", saveAttribute);
  elements.imageForm.addEventListener("submit", saveImage);
}

async function init() {
  setupListeners();
  attachDelegatedEvents();
  if (token) {
    try {
      await initializeAdmin();
      showApp();
    } catch {
      logout();
    }
  } else {
    showLogin();
  }
}

init();
