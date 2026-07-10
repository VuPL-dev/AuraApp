import { Request, Response } from "express";
import prisma from "../prisma";
const payosModule = require("@payos/node");
const PayOS = payosModule.PayOS || payosModule;

export const createPayosPayment = async (req: any, res: Response): Promise<void> => {
  try {
    const { PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY, PAYOS_RETURN_URL, PAYOS_CANCEL_URL } = process.env;
    
    const userId = req.user.id;
    const { address_id, total_amount, payment_method, items } = req.body;

    const newOrder = await prisma.order.create({
      data: {
        user_id: userId,
        address_id,
        total_amount,
        payment_method: "BANK_TRANSFER",
        status: "PENDING",
        items: {
          create: items.map((item: any) => ({
            product_id: item.product_id,
            quantity: item.quantity,
            unit_price: item.unit_price,
          })),
        },
      },
    });

    const amount = Number(total_amount);
    const orderCode = Number(String(Date.now()).slice(-6) + String(newOrder.id)); 

    await prisma.payment.create({
      data: {
        order_id: newOrder.id,
        amount: amount,
        provider: "PAYOS",
        status: "PENDING",
        transaction_id: orderCode.toString(),
      },
    });

    let checkoutUrl = "";
    const isMock = !PAYOS_CLIENT_ID || !PAYOS_API_KEY || !PAYOS_CHECKSUM_KEY || PAYOS_CLIENT_ID === "mock";

    if (isMock) {
      const host = req.headers.host || "localhost:5000";
      checkoutUrl = `http://${host}/api/payment/mock-payos-checkout?orderCode=${orderCode}&amount=${amount}`;
    } else {
      const payos = new PayOS(
        PAYOS_CLIENT_ID,
        PAYOS_API_KEY,
        PAYOS_CHECKSUM_KEY
      );

      const returnUrl = PAYOS_RETURN_URL || `http://${req.headers.host || 'localhost:5000'}/api/payment/payos-return`;
      const cancelUrl = PAYOS_CANCEL_URL || `http://${req.headers.host || 'localhost:5000'}/api/payment/payos-cancel`;

      // description tối đa 25 ký tự
      const desc = `DH${newOrder.id} AURA`.slice(0, 25);

      const body = {
        orderCode: orderCode,
        amount: amount,
        description: desc,
        items: items.map((item: any) => ({
          name: `SP ${item.product_id || 'N'}`.slice(0, 25),
          quantity: item.quantity,
          price: Math.round(item.unit_price),
        })),
        returnUrl,
        cancelUrl,
      };

      console.log('[PayOS] Creating payment link with body:', JSON.stringify(body));
      const paymentLinkRes = await payos.createPaymentLink(body);
      checkoutUrl = paymentLinkRes.checkoutUrl;
    }

    res.status(201).json({
      order_id: newOrder.id,
      checkoutUrl: checkoutUrl,
      orderCode: orderCode,
    });
  } catch (error: any) {
    console.error("[PayOS] Error creating payment:", error.message || error);
    res.status(500).json({ error: "Server error", details: error.message });
  }
};

export const handlePayosWebhook = async (req: Request, res: Response): Promise<void> => {
  try {
    const { PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY } = process.env;
    const isMock = !PAYOS_CLIENT_ID || !PAYOS_API_KEY || !PAYOS_CHECKSUM_KEY || PAYOS_CLIENT_ID === "mock";

    let webhookData: any;

    if (isMock) {
      webhookData = req.body.data || req.body;
    } else {
      const payos = new PayOS(
        PAYOS_CLIENT_ID!,
        PAYOS_API_KEY!,
        PAYOS_CHECKSUM_KEY!
      );
      webhookData = payos.verifyPaymentWebhookData(req.body);
    }

    if (webhookData.code === "00") {
      const orderCodeStr = webhookData.orderCode.toString();
      
      const payment = await prisma.payment.findFirst({
        where: { transaction_id: orderCodeStr, provider: "PAYOS" }
      });

      if (!payment) {
        res.status(404).json({ error: "Payment not found" });
        return;
      }

      const orderId = payment.order_id;

      await prisma.$transaction([
        prisma.payment.update({
          where: { id: payment.id },
          data: { status: "PAID" },
        }),
        prisma.order.update({
          where: { id: orderId },
          data: { status: "PAID" },
        }),
        prisma.notification.create({
          data: {
            user_id: (await prisma.order.findUnique({ where: { id: orderId } }))!.user_id!,
            title: "Thanh toan thanh cong",
            message: `Don hang #${orderId} da duoc thanh toan thanh cong qua PayOS.`,
          },
        }),
      ]);
    }

    res.status(200).json({ success: true });
  } catch (error: any) {
    console.error("[PayOS] Webhook error:", error.message || error);
    res.status(400).json({ error: "Invalid webhook" });
  }
};

export const handleMockPayosCheckout = async (req: Request, res: Response): Promise<void> => {
  try {
    const { orderCode, amount } = req.query;
    const orderCodeStr = orderCode as string;

    const payment = await prisma.payment.findFirst({
      where: { transaction_id: orderCodeStr, provider: "PAYOS" }
    });

    if (!payment) {
      res.status(404).send("<h1>Order not found</h1>");
      return;
    }

    res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>PayOS Mock Checkout</title>
          <style>
            body { font-family: 'Segoe UI', sans-serif; background-color: #0f0f11; color: #fff; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
            .card { background-color: #18181c; border-radius: 16px; padding: 30px; max-width: 450px; width: 100%; box-shadow: 0 8px 30px rgba(0,0,0,0.5); border: 1px solid #2d2d34; text-align: center; }
            .logo { font-size: 24px; font-weight: bold; color: #D4AF37; letter-spacing: 2px; margin-bottom: 20px; }
            .amount { font-size: 36px; font-weight: bold; color: #D4AF37; margin: 15px 0; }
            .btn { display: block; width: 100%; padding: 14px; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; margin-bottom: 12px; border: none; }
            .btn-success { background-color: #5cb85c; color: white; }
            .btn-cancel { background-color: transparent; color: #d9534f; border: 1px solid #d9534f; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="logo">AURA PAYOS MOCK</div>
            <div class="amount">${Number(amount).toLocaleString('vi-VN')} VND</div>
            <p>Ma don: ${orderCodeStr} | DB ID: #${payment.order_id}</p>
            <button class="btn btn-success" onclick="confirmPayment()">XAC NHAN THANH TOAN</button>
            <button class="btn btn-cancel" onclick="cancelPayment()">HUY GIAO DICH</button>
          </div>
          <script>
            async function confirmPayment() {
              await fetch('/api/payment/payos-webhook', {
                method: 'POST', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ success: true, data: { orderCode: ${orderCodeStr}, amount: ${amount}, code: '00', desc: 'success' } })
              });
              window.location.href = '/api/payment/payos-return?status=PAID&orderCode=${orderCodeStr}';
            }
            function cancelPayment() {
              window.location.href = '/api/payment/payos-cancel?status=CANCELLED&orderCode=${orderCodeStr}';
            }
          </script>
        </body>
      </html>
    `);
  } catch (error: any) {
    res.status(500).send("<h1>Mock Checkout Error</h1>");
  }
};

export const handlePayosReturn = async (req: Request, res: Response): Promise<void> => {
  const { orderCode, status, cancel } = req.query;
  if (cancel === "true" || status === "CANCELLED") {
    res.send(`<html><body style="font-family:sans-serif;text-align:center;padding-top:50px"><h2 style="color:#d9534f">Thanh toan da huy</h2><p>Ma: ${orderCode}</p></body></html>`);
    return;
  }
  if (status === "PAID") {
    res.send(`<html><body style="font-family:sans-serif;text-align:center;padding-top:50px"><h2 style="color:#5cb85c">Thanh toan thanh cong!</h2><p>Ma: ${orderCode}</p></body></html>`);
    return;
  }
  res.send("Status: " + status);
};
