const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:5000/api';

async function test() {
  console.log('🚀 BẮT ĐẦU KIỂM TRA TỰ ĐỘNG CÁC API VÀ TÍNH NĂNG UPLOAD...\n');

  // 1. ĐĂNG NHẬP
  console.log('1. Đang đăng nhập tài khoản Admin (admin@aura.com)...');
  let token;
  try {
    const loginRes = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@aura.com', password: '123456' }),
    });

    const loginData = await loginRes.json();
    if (!loginRes.ok) {
      throw new Error(loginData.error || 'Đăng nhập thất bại');
    }

    token = loginData.token;
    console.log('   ✅ Đăng nhập thành công!');
  } catch (error) {
    console.error('   ❌ Thất bại:', error.message);
    console.log('\n💡 Lưu ý: Hãy chắc chắn rằng database của bạn đã được seed (chạy node seed_roles.js) và server đang hoạt động.');
    return;
  }

  // 2. UPLOAD ẢNH
  console.log('\n2. Đang kiểm tra tính năng Upload ảnh...');
  const sampleImagePath = path.join(__dirname, 'uploads', 'donghonam.webp');
  if (!fs.existsSync(sampleImagePath)) {
    console.error(`   ❌ Thất bại: Không tìm thấy file ảnh mẫu tại ${sampleImagePath}`);
    return;
  }

  let uploadedImageUrl;
  try {
    const imageBuffer = fs.readFileSync(sampleImagePath);
    const blob = new Blob([imageBuffer], { type: 'image/webp' });
    const formData = new FormData();
    formData.append('image', blob, 'test_upload.webp');

    const uploadRes = await fetch(`${BASE_URL}/products/upload`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    });

    const uploadData = await uploadRes.json();
    if (!uploadRes.ok) {
      throw new Error(uploadData.error || 'Upload ảnh thất bại');
    }

    uploadedImageUrl = uploadData.url;
    console.log('   ✅ Upload ảnh thành công!');
    console.log('      - URL tương đối:', uploadData.url);
    console.log('      - URL đầy đủ:', uploadData.full_url);
    console.log('      - Tên file lưu trên server:', uploadData.filename);
  } catch (error) {
    console.error('   ❌ Thất bại:', error.message);
    return;
  }

  // 3. THÊM SẢN PHẨM MỚI (DÙNG ẢNH VỪA UPLOAD)
  console.log('\n3. Đang kiểm tra Thêm sản phẩm mới...');
  let createdProductId;
  try {
    const productRes = await fetch(`${BASE_URL}/products`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        name: 'Sản phẩm Test Tự Động',
        description: 'Mô tả sản phẩm test tự động tạo bởi script',
        price: 199000,
        stock_quantity: 10,
        sku: 'SKU-TEST-' + Date.now(),
        brand: 'Aura',
        images: [uploadedImageUrl]
      })
    });

    const productData = await productRes.json();
    if (!productRes.ok) {
      throw new Error(productData.error || 'Thêm sản phẩm thất bại');
    }

    createdProductId = productData.id;
    console.log(`   ✅ Thêm sản phẩm thành công! ID: ${createdProductId}`);
  } catch (error) {
    console.error('   ❌ Thất bại:', error.message);
    return;
  }

  // 4. CẬP NHẬT SẢN PHẨM (PUT)
  console.log('\n4. Đang kiểm tra Cập nhật sản phẩm (API PUT)...');
  try {
    const updateRes = await fetch(`${BASE_URL}/products/${createdProductId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        name: 'Sản phẩm Test Tự Động - ĐÃ CẬP NHẬT',
        price: 250000,
        stock_quantity: 20
      })
    });

    const updateData = await updateRes.json();
    if (!updateRes.ok) {
      throw new Error(updateData.error || 'Cập nhật thất bại');
    }

    console.log('   ✅ Cập nhật sản phẩm thành công!');
    console.log('      - Tên mới:', updateData.name);
    console.log('      - Giá mới:', updateData.price);
    console.log('      - Số lượng mới:', updateData.stock_quantity);
  } catch (error) {
    console.error('   ❌ Thất bại:', error.message);
    return;
  }

  // 5. XÓA SẢN PHẨM (DELETE)
  console.log('\n5. Đang kiểm tra Xóa sản phẩm (API DELETE)...');
  try {
    const deleteRes = await fetch(`${BASE_URL}/products/${createdProductId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    const deleteData = await deleteRes.json();
    if (!deleteRes.ok) {
      throw new Error(deleteData.error || 'Xóa thất bại');
    }

    console.log('   ✅ Xóa sản phẩm thành công!');
    console.log('      - Phản hồi từ server:', deleteData.message);
  } catch (error) {
    console.error('   ❌ Thất bại:', error.message);
    return;
  }

  console.log('\n🎉 TẤT CẢ CÁC TÍNH NĂNG ĐÃ HOẠT ĐỘNG HOÀN HẢO! 🎉');
}

test();
