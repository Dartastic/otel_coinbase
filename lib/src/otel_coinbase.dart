// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_coinbase_suppression.dart';

const _tracerName = 'dartastic_otel_libs_coinbase';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class CoinbaseResult {
  const CoinbaseResult({
    this.surface,
    this.productId,
    this.side,
    this.orderId,
    this.clientOrderId,
    this.orderType,
    this.orderStatus,
    this.timeInForce,
    this.baseQuantity,
    this.quoteSize,
    this.filledSize,
    this.averageFilledPrice,
    this.feeCents,
    this.feeCurrency,
    this.account,
    this.chargeId,
    this.chargeCode,
    this.pricingType,
    this.chargeStatus,
    this.payerEmail,
    this.localAmount,
    this.localCurrency,
    this.cryptoAmount,
    this.cryptoCurrency,
    this.network,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `advanced_trade`, `commerce`, `pay`, `prime`, `developer_platform`.
  final String? surface;

  // ── Advanced Trade ─────────────────────────────────────────────
  final String? productId;

  /// `BUY` / `SELL`.
  final String? side;

  final String? orderId;
  final String? clientOrderId;

  /// `MARKET`, `LIMIT`, `STOP_LIMIT`, `BRACKET`, `TWAP`.
  final String? orderType;

  /// `OPEN`, `FILLED`, `CANCELLED`, `EXPIRED`, `FAILED`.
  final String? orderStatus;

  /// `GTC`, `GTD`, `IOC`, `FOK`.
  final String? timeInForce;

  final String? baseQuantity;
  final String? quoteSize;
  final String? filledSize;
  final String? averageFilledPrice;

  final int? feeCents;
  final String? feeCurrency;

  /// Account profile / portfolio.
  final String? account;

  // ── Commerce (merchant checkout) ───────────────────────────────
  final String? chargeId;
  final String? chargeCode;

  /// `fixed_price`, `no_price`, `direct_charge`.
  final String? pricingType;

  /// `NEW`, `PENDING`, `COMPLETED`, `EXPIRED`, `UNRESOLVED`,
  /// `RESOLVED`, `CANCELED`, `PENDING_REFUND`, `REFUNDED`.
  final String? chargeStatus;

  final String? payerEmail;

  final String? localAmount;
  final String? localCurrency;

  final String? cryptoAmount;

  /// `BTC`, `ETH`, `USDC`, `DAI`, `LTC`, `BCH`, `DOGE`, `APE`, `MATIC`,
  /// `SHIB`.
  final String? cryptoCurrency;

  /// On-chain network: `ethereum`, `base`, `polygon`, `arbitrum`,
  /// `optimism`, `bitcoin`, `litecoin`, `dogecoin`, `solana`.
  final String? network;

  /// Coinbase API error code (`invalid_request`, `unauthorized`,
  /// `invalid_scope`, `expired_token`, `revoked_token`, `insufficient_funds`,
  /// `invalid_signature`, `not_found`, `rate_limit_exceeded`,
  /// `validation_error`, `internal_server_error`).
  final String? errorCode;
  final String? errorMessage;

  final int? statusCode;
}

class CoinbaseCallResult<T> {
  const CoinbaseCallResult({required this.value, this.result});
  final T value;
  final CoinbaseResult? result;
}

/// Wraps a Coinbase API call in a CLIENT span. [operation] is one of
/// `advanced_trade.createOrder`, `advanced_trade.cancelOrders`,
/// `advanced_trade.listOrders`, `advanced_trade.getOrder`,
/// `advanced_trade.listAccounts`, `advanced_trade.getAccount`,
/// `advanced_trade.listProducts`, `advanced_trade.getProduct`,
/// `advanced_trade.getProductBook`, `advanced_trade.getProductCandles`,
/// `advanced_trade.previewOrder`, `advanced_trade.getFills`,
/// `advanced_trade.getTransactionSummary`, `advanced_trade.editOrder`,
/// `commerce.createCharge`, `commerce.showCharge`, `commerce.listCharges`,
/// `commerce.cancelCharge`, `commerce.resolveCharge`,
/// `commerce.listCheckouts`, `commerce.createCheckout`,
/// `commerce.showCheckout`, `commerce.cancelCheckout`,
/// `commerce.webhook.verify`, `pay.getBuyQuote`, `pay.commitBuy`,
/// `developer_platform.getOnrampUrl`, `developer_platform.getOfframpUrl`,
/// `prime.listAccounts`, `prime.listTransactions`.
Future<T> tracedCoinbase<T>({
  required String operation,
  required Future<CoinbaseCallResult<T>> Function() invoke,
}) async {
  if (coinbaseInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'coinbase',
    'rpc.method': operation,
    'coinbase.operation': operation,
  };

  final span = _tracer().startSpan(
    'coinbase $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.surface != null) {
        extras.add(OTel.attributeString('coinbase.surface', res.surface!));
      }
      if (res.productId != null) {
        extras.add(OTel.attributeString(
          'coinbase.product.id',
          res.productId!,
        ));
      }
      if (res.side != null) {
        extras.add(OTel.attributeString('coinbase.order.side', res.side!));
      }
      if (res.orderId != null) {
        extras.add(OTel.attributeString('coinbase.order.id', res.orderId!));
      }
      if (res.clientOrderId != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.client_id',
          res.clientOrderId!,
        ));
      }
      if (res.orderType != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.type',
          res.orderType!,
        ));
      }
      if (res.orderStatus != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.status',
          res.orderStatus!,
        ));
        if (res.orderStatus == 'FAILED' || res.orderStatus == 'EXPIRED') {
          span.setStatus(
            SpanStatusCode.Error,
            'Coinbase order ${res.orderStatus}',
          );
        }
      }
      if (res.timeInForce != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.tif',
          res.timeInForce!,
        ));
      }
      if (res.baseQuantity != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.base_quantity',
          res.baseQuantity!,
        ));
      }
      if (res.quoteSize != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.quote_size',
          res.quoteSize!,
        ));
      }
      if (res.filledSize != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.filled_size',
          res.filledSize!,
        ));
      }
      if (res.averageFilledPrice != null) {
        extras.add(OTel.attributeString(
          'coinbase.order.avg_filled_price',
          res.averageFilledPrice!,
        ));
      }
      if (res.feeCents != null) {
        extras.add(OTel.attributeInt('coinbase.fee.cents', res.feeCents!));
      }
      if (res.feeCurrency != null) {
        extras.add(OTel.attributeString(
          'coinbase.fee.currency',
          res.feeCurrency!,
        ));
      }
      if (res.account != null) {
        extras.add(OTel.attributeString('coinbase.account', res.account!));
      }
      if (res.chargeId != null) {
        extras.add(OTel.attributeString('coinbase.charge.id', res.chargeId!));
      }
      if (res.chargeCode != null) {
        extras.add(OTel.attributeString(
          'coinbase.charge.code',
          res.chargeCode!,
        ));
      }
      if (res.pricingType != null) {
        extras.add(OTel.attributeString(
          'coinbase.charge.pricing_type',
          res.pricingType!,
        ));
      }
      if (res.chargeStatus != null) {
        extras.add(OTel.attributeString(
          'coinbase.charge.status',
          res.chargeStatus!,
        ));
        if (res.chargeStatus == 'EXPIRED' || res.chargeStatus == 'UNRESOLVED') {
          span.setStatus(
            SpanStatusCode.Error,
            'Coinbase charge ${res.chargeStatus}',
          );
        }
      }
      if (res.payerEmail != null) {
        extras.add(OTel.attributeString(
          'coinbase.payer.email',
          res.payerEmail!,
        ));
      }
      if (res.localAmount != null) {
        extras.add(OTel.attributeString(
          'coinbase.charge.local_amount',
          res.localAmount!,
        ));
      }
      if (res.localCurrency != null) {
        extras.add(OTel.attributeString(
          'coinbase.charge.local_currency',
          res.localCurrency!,
        ));
      }
      if (res.cryptoAmount != null) {
        extras.add(OTel.attributeString(
          'coinbase.charge.crypto_amount',
          res.cryptoAmount!,
        ));
      }
      if (res.cryptoCurrency != null) {
        extras.add(OTel.attributeString(
          'coinbase.charge.crypto_currency',
          res.cryptoCurrency!,
        ));
      }
      if (res.network != null) {
        extras.add(OTel.attributeString('coinbase.network', res.network!));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'coinbase.error.code',
          res.errorCode!,
        ));
        span.setStatus(SpanStatusCode.Error, 'Coinbase ${res.errorCode}');
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'coinbase.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Coinbase HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
