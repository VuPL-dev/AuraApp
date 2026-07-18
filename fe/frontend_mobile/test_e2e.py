"""
Test E2E thật cho AURA Assistant - mô phỏng chính xác cách GeminiService.dart gọi API.
Sử dụng key thật từ file .env và model gemini-flash-lite-latest.

Kiểm tra:
1. Pipeline RAG 5 bước (filter -> format -> system prompt -> temperature 0.4)
2. AI trả lời đúng dựa trên context (không bịa)
3. AI từ chối câu hỏi ngoài phạm vi
4. AI trả lời "chưa có thông tin" khi thiếu data
"""
import os
import json
import time
import urllib.request
import urllib.error
from pathlib import Path

# Load key từ file .env (giống hệt flutter_dotenv)
env_path = Path(__file__).parent / ".env"
env_vars = {}
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env_vars[k.strip()] = v.strip()

API_KEY = env_vars["GEMINI_API_KEY"]
BASE_URL = env_vars["GEMINI_BASE_URL"]
MODEL = env_vars["GEMINI_MODEL"]

print(f"[*] Using API key: {API_KEY[:20]}...")
print(f"[*] Model: {MODEL}")
print(f"[*] Base URL: {BASE_URL}")
print("=" * 70)

# ============= BƯỚC 1: Model Class (đã có trong knowledge_base.dart) =============
KNOWLEDGE_BASE = [
    {
        "id": 1, "name": "Đồng Hồ Nam Dây Da Cao Cấp", "brand": "AURA",
        "price": 10000, "sku": "DH-NAM-001", "category": "Đồng hồ Nam",
        "description": "Đồng hồ nam thời trang với dây da sang trọng, mặt kính sapphire chống xước. Phù hợp đi làm và dự tiệc.",
        "suitableFor": "Nam giới công sở, dự tiệc, sự kiện trang trọng",
        "warnings": "Tránh để tiếp xúc nước nóng và hóa chất. Không đeo khi chơi thể thao dưới nước.",
        "returnPolicy": "Đổi trả trong 30 ngày nếu lỗi kỹ thuật hoặc đóng gói.",
    },
    {
        "id": 2, "name": "Đồng Hồ Nam Luxury Collection", "brand": "AURA",
        "price": 10000, "sku": "DH-NAM-002", "category": "Đồng hồ Nam",
        "description": "Bộ sưu tập đồng hồ nam luxury, vỏ thép không gỉ 316L, chống nước 50m.",
        "suitableFor": "Nam giới yêu thích phong cách sang trọng, quý ông hiện đại",
        "warnings": "Chống nước 50m — không đeo khi lặn biển.",
        "returnPolicy": "Đổi trả trong 30 ngày. Bảo hành chính hãng 12 tháng.",
    },
    {
        "id": 3, "name": "Đồng Hồ Nam Sport Edition", "brand": "AURA",
        "price": 10000, "sku": "DH-NAM-003", "category": "Đồng hồ Nam",
        "description": "Đồng hồ thể thao nam, dây silicon bền chắc, đo nhịp tim, chống nước 100m.",
        "suitableFor": "Nam giới năng động, chơi thể thao, tập gym, chạy bộ",
        "warnings": "Chống nước 100m phù hợp bơi lội nhưng không lặn sâu.",
        "returnPolicy": "Đổi trả trong 30 ngày. Pin bảo hành 6 tháng.",
    },
    {
        "id": 4, "name": "Vòng Cổ Nam Bạc 925", "brand": "AURA",
        "price": 10000, "sku": "VC-NAM-001", "category": "Combo phụ kiện",
        "description": "Dây chuyền vòng cổ nam bạc 925 nguyên chất, không gây dị ứng.",
        "suitableFor": "Nam giới mọi lứa tuổi, phong cách cá tính hoặc công sở",
        "warnings": "Tháo khi tắm, bơi lội, chơi thể thao.",
        "returnPolicy": "Đổi trả trong 30 ngày nếu lỗi kỹ thuật.",
    },
    {
        "id": 5, "name": "Combo Mắt Kính & Đồng Hồ Nam", "brand": "AURA",
        "price": 10000, "sku": "COMBO-001", "category": "Combo phụ kiện",
        "description": "Bộ combo thời trang nam gồm mắt kính UV400 và đồng hồ cổ điển.",
        "suitableFor": "Quà tặng sinh nhật, kỷ niệm, ngày lễ cho nam giới",
        "warnings": "Không dùng khăn giấy lau tròng kính.",
        "returnPolicy": "Combo đổi trả trong 30 ngày nếu lỗi kỹ thuật.",
    },
]

SHOP_INFO = {
    "name": "AURA Accessories",
    "tagline": "Thương hiệu phụ kiện thời trang cao cấp Việt Nam.",
    "hotline": "1900 8888",
    "supportEmail": "support@aura-accessories.vn",
    "returnPolicy": "Đổi sản phẩm mới hoặc hoàn tiền trong vòng 30 ngày nếu lỗi kỹ thuật.",
    "shippingPolicy": "Miễn phí vận chuyển toàn quốc cho đơn từ 250.000đ. Đơn dưới 250.000đ phí 25.000đ.",
    "authPolicy": "Tất cả sản phẩm chính hãng 100%.",
    "promo": "Giảm đến 30% Bộ sưu tập mới 2025. Hỗ trợ trả góp 0% qua PayOS cho đơn từ 500.000đ.",
    "payment": "PayOS, COD",
}

# ============= BƯỚC 2: Local Filtering (giống searchRelevantProducts) =============
def search_relevant(query, top_k=5):
    if not query or len(query) < 2:
        return KNOWLEDGE_BASE[:top_k]
    query_lower = query.lower()
    words = [w for w in query_lower.split() if len(w) > 1]
    if not words:
        return KNOWLEDGE_BASE[:top_k]

    scored = []
    for p in KNOWLEDGE_BASE:
        score = 0
        for w in words:
            if w in p["name"].lower(): score += 3
            if w in p["brand"].lower(): score += 3
            if w in (p.get("sku") or "").lower(): score += 4
            if w in p["category"].lower(): score += 2
            if w in p["description"].lower(): score += 1
            if w in p["warnings"].lower(): score += 1
            if w in p["returnPolicy"].lower(): score += 1
        if score > 0:
            scored.append((p, score))

    scored.sort(key=lambda x: -x[1])
    return [p for p, _ in scored[:top_k]]

# ============= BƯỚC 3: Format Context =============
def format_product_context(products):
    if not products:
        return "Không tìm thấy sản phẩm liên quan trong kho dữ liệu."
    lines = []
    for i, p in enumerate(products, 1):
        lines.append(f"--- Sản phẩm {i} (ID: {p['id']}) ---")
        lines.append(f"Tên: {p['name']}")
        lines.append(f"Thương hiệu: {p['brand']}")
        if p.get("sku"): lines.append(f"Mã SKU: {p['sku']}")
        lines.append(f"Danh mục: {p['category']}")
        lines.append(f"Giá: {p['price']:,} VND")
        lines.append(f"Tồn kho: 50 sản phẩm")
        lines.append(f"Mô tả: {p['description']}")
        lines.append(f"Phù hợp cho: {p['suitableFor']}")
        lines.append(f"Chính sách đổi trả: {p['returnPolicy']}")
        lines.append(f"Lưu ý: {p['warnings']}")
        lines.append("")
    return "\n".join(lines)

def format_shop_context():
    return f"""--- Thông tin cửa hàng ---
Tên: {SHOP_INFO['name']}
Mô tả: {SHOP_INFO['tagline']}
Hotline: {SHOP_INFO['hotline']}
Email hỗ trợ: {SHOP_INFO['supportEmail']}
Chính sách đổi trả: {SHOP_INFO['returnPolicy']}
Chính sách vận chuyển: {SHOP_INFO['shippingPolicy']}
Cam kết chính hãng: {SHOP_INFO['authPolicy']}
Khuyến mãi hiện tại: {SHOP_INFO['promo']}
Phương thức thanh toán: {SHOP_INFO['payment']}"""

# ============= BƯỚC 4: System Prompt =============
SYSTEM_PROMPT = """Bạn là Aura Assistant, trợ lý tư vấn chuyên nghiệp của cửa hàng phụ kiện thời trang AURA Accessories.
Chỉ được trả lời dựa trên NỘI DUNG CÓ SẴN được cung cấp bên dưới (gồm thông tin sản phẩm và thông tin cửa hàng).
Không được tự suy đoán hoặc bịa thông tin (giá, thông số kỹ thuật, chính sách, tên sản phẩm, v.v.).
Nếu câu hỏi có trong nội dung có sẵn: trả lời ngắn gọn, đúng thông tin, có dẫn chứng cụ thể.
Nếu câu hỏi liên quan đến sản phẩm AURA nhưng thiếu dữ liệu: trả lời rõ "Hiện chưa có thông tin này trong dữ liệu của AURA."
Nếu câu hỏi không liên quan đến phụ kiện thời trang hoặc sản phẩm AURA: từ chối lịch sự.
Ví dụ: "Xin lỗi, tôi chỉ có thể hỗ trợ tư vấn về sản phẩm và dịch vụ tại AURA Accessories."
Khi người dùng hỏi về chính sách đổi trả, vận chuyển, thanh toán hoặc liên hệ: dựa vào phần "Thông tin cửa hàng" trong context.
Luôn trả lời bằng tiếng Việt, ngắn gọn, lịch sự và chuyên nghiệp."""

def build_prompt(user_q):
    products = search_relevant(user_q)
    p_ctx = format_product_context(products)
    s_ctx = format_shop_context()
    return f"""{SYSTEM_PROMPT}

=== THÔNG TIN CỬA HÀNG ===
{s_ctx}

=== SẢN PHẨM LIÊN QUAN ===
{p_ctx}

=== CÂU HỎI CỦA NGƯỜI DÙNG ===
{user_q}

=== CÂU TRẢ LỜI ==="""

def call_gemini(user_q, timeout=30):
    prompt = build_prompt(user_q)
    url = f"{BASE_URL}/models/{MODEL}:generateContent?key={API_KEY}"
    payload = {
        "contents": [{"role": "user", "parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.4, "topP": 0.9, "maxOutputTokens": 800},
        "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
        ],
    }
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read())
            candidates = data.get("candidates") or []
            if not candidates:
                return "[EMPTY] Không có candidates", None
            text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
            return text, data.get("usageMetadata")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        try:
            msg = json.loads(body).get("error", {}).get("message", body[:200])
        except Exception:
            msg = body[:200]
        return f"[HTTP {e.code}] {msg}", None
    except Exception as e:
        return f"[ERROR] {type(e).__name__}: {e}", None

# ============= TEST CASES (theo đề bài PRM393) =============
TEST_CASES = [
    # (question, expected_keywords_in_answer, should_NOT_contain, description)
    ("Có những đồng hồ nào đang bán?", ["đồng hồ"], [], "Liệt kê sản phẩm"),
    ("Đồng Hồ Nam Luxury giá bao nhiêu?", ["10.000", "10,000"], [], "Hỏi giá cụ thể"),
    ("Chính sách đổi trả như thế nào?", ["30 ngày"], [], "Hỏi chính sách"),
    ("Combo quà tặng có gì?", ["mắt kính", "đồng hồ"], [], "Hỏi về combo"),
    ("Vòng cổ bạc 925 có phù hợp không?", ["bạc", "925"], [], "Hỏi sản phẩm cụ thể"),
    ("Viết bài thơ cho tôi", ["Xin lỗi"], ["bài thơ"], "Từ chối câu ngoài phạm vi"),
    ("Shop mở cửa mấy giờ?", ["Hiện chưa có thông tin"], [], "Câu hỏi thiếu data"),
    ("Có hỗ trợ trả góp không?", ["PayOS", "trả góp"], [], "Hỏi thanh toán"),
    ("Hotline AURA là gì?", ["1900 8888"], [], "Hỏi liên hệ"),
    ("Miễn phí vận chuyển không?", ["250.000"], [], "Hỏi vận chuyển"),
]

print("\n[*] Starting E2E test...\n")
passed = 0
failed = 0
for i, (q, must_have, must_not, desc) in enumerate(TEST_CASES, 1):
    print(f"\n{'─' * 70}")
    print(f"[Test {i:2d}/{len(TEST_CASES)}] {desc}")
    print(f"[Q] {q}")
    answer, usage = call_gemini(q)
    # Nếu bị rate limit, đợi 65s rồi retry 1 lần
    if "[HTTP 429]" in answer:
        print("[!] Rate limited, đợi 65s...")
        time.sleep(65)
        answer, usage = call_gemini(q)
    if usage:
        print(f"[usage] prompt={usage.get('promptTokenCount','?')} "
              f"output={usage.get('candidatesTokenCount','?')} "
              f"total={usage.get('totalTokenCount','?')}")
    print(f"[A] {answer[:300]}{'...' if len(answer) > 300 else ''}")
    # Delay giữa các request để tránh rate limit
    if i < len(TEST_CASES):
        time.sleep(8)

    # Validate - chấp nhận cả dấu phẩy và dấu chấm cho số
    answer_normalized = answer.replace(",", ".")
    answer_lower = answer_normalized.lower()
    ok = all(kw.replace(",", ".").lower() in answer_lower for kw in must_have)
    ok = ok and all(kw.replace(",", ".").lower() not in answer_lower for kw in must_not)
    # Bỏ check keyword nếu AI từ chối (vì câu hỏi ngoài phạm vi)
    if "Xin lỗi" in answer and must_have == []:
        ok = True

    status = "PASS" if ok else "FAIL"
    if ok:
        passed += 1
    else:
        failed += 1
    missing = [kw for kw in must_have if kw.lower() not in answer_lower]
    forbidden_found = [kw for kw in must_not if kw.lower() in answer_lower]
    if missing:
        print(f"[!] Thiếu keyword: {missing}")
    if forbidden_found:
        print(f"[!] Chứa từ khóa bị cấm: {forbidden_found}")
    print(f"[{status}]")

print(f"\n{'=' * 70}")
print(f"[RESULT] Passed: {passed}/{len(TEST_CASES)} | Failed: {failed}")
print(f"{'=' * 70}")