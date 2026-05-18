// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_coinbase/otel_coinbase.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_coinbase-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('advanced_trade.createOrder records product + side + status', () async {
    await tracedCoinbase<String>(
      operation: 'advanced_trade.createOrder',
      invoke: () async => const CoinbaseCallResult(
        value: 'ok',
        result: CoinbaseResult(
          surface: 'advanced_trade',
          productId: 'BTC-USD',
          side: 'BUY',
          orderId: 'o_1',
          orderType: 'LIMIT',
          orderStatus: 'OPEN',
          timeInForce: 'GTC',
          baseQuantity: '0.01',
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('coinbase advanced_trade.createOrder')!,
    );
    expect(a['coinbase.product.id'], 'BTC-USD');
    expect(a['coinbase.order.tif'], 'GTC');
  });

  test('FAILED order status sets span error', () async {
    await tracedCoinbase<String>(
      operation: 'advanced_trade.createOrder',
      invoke: () async => const CoinbaseCallResult(
        value: 'ok',
        result: CoinbaseResult(orderStatus: 'FAILED'),
      ),
    );
    expect(
      spans.findSpanByName('coinbase advanced_trade.createOrder')!.status,
      SpanStatusCode.Error,
    );
  });

  test('commerce.createCharge records charge + crypto + network', () async {
    await tracedCoinbase<String>(
      operation: 'commerce.createCharge',
      invoke: () async => const CoinbaseCallResult(
        value: 'ok',
        result: CoinbaseResult(
          surface: 'commerce',
          chargeId: 'chg_1',
          chargeCode: 'ABCDEFGH',
          pricingType: 'fixed_price',
          chargeStatus: 'NEW',
          localAmount: '49.99',
          localCurrency: 'USD',
          cryptoCurrency: 'USDC',
          network: 'base',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('coinbase commerce.createCharge')!);
    expect(a['coinbase.charge.code'], 'ABCDEFGH');
    expect(a['coinbase.network'], 'base');
  });

  test('EXPIRED commerce charge sets span error', () async {
    await tracedCoinbase<String>(
      operation: 'commerce.showCharge',
      invoke: () async => const CoinbaseCallResult(
        value: 'ok',
        result: CoinbaseResult(chargeStatus: 'EXPIRED'),
      ),
    );
    expect(
      spans.findSpanByName('coinbase commerce.showCharge')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutCoinbaseInstrumentationAsync(() async {
      await tracedCoinbase<String>(
        operation: 'advanced_trade.listProducts',
        invoke: () async => const CoinbaseCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('coinbase '), isEmpty);
  });
}
