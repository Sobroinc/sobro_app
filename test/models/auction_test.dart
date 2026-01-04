import 'package:flutter_test/flutter_test.dart';
import 'package:sobro_app/features/auctions/auctions_provider.dart';

void main() {
  group('Auction', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'product_id': 1,
        'product_title': 'Excavator CAT 320',
        'current_price': 50000.0,
        'bids_count': 15,
        'ends_at': '2024-12-31T23:59:59Z',
        'timezone': 'Europe/Berlin',
        'time_remaining_seconds': 7200,
        'image_url': '/images/excavator.jpg',
        'winner_name': 'John Doe',
      };

      final auction = Auction.fromJson(json);

      expect(auction.productId, 1);
      expect(auction.productTitle, 'Excavator CAT 320');
      expect(auction.currentPrice, 50000.0);
      expect(auction.bidsCount, 15);
      expect(auction.endsAt, DateTime.parse('2024-12-31T23:59:59Z'));
      expect(auction.timezone, 'Europe/Berlin');
      expect(auction.timeRemainingSeconds, 7200);
      expect(auction.imageUrl, '/images/excavator.jpg');
      expect(auction.winnerName, 'John Doe');
    });

    test('fromJson uses default values', () {
      final json = {
        'product_id': 1,
        'product_title': 'Test',
        'current_price': 1000,
        'ends_at': '2024-12-31T23:59:59Z',
      };

      final auction = Auction.fromJson(json);

      expect(auction.bidsCount, 0);
      expect(auction.timezone, 'UTC');
      expect(auction.timeRemainingSeconds, isNull);
      expect(auction.imageUrl, isNull);
      expect(auction.winnerName, isNull);
    });

    group('isEnding', () {
      test('returns true when less than 1 hour remaining', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 3599, // 59 minutes 59 seconds
        );

        expect(auction.isEnding, true);
      });

      test('returns false when more than 1 hour remaining', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 3601, // 1 hour 1 second
        );

        expect(auction.isEnding, false);
      });

      test('returns true when timeRemainingSeconds is null', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
        );

        expect(auction.isEnding, true);
      });
    });

    group('isActive', () {
      test('returns true when time remaining is positive', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 100,
        );

        expect(auction.isActive, true);
      });

      test('returns false when time remaining is zero', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 0,
        );

        expect(auction.isActive, false);
      });

      test('returns false when time remaining is negative', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: -100,
        );

        expect(auction.isActive, false);
      });
    });

    group('timeRemaining', () {
      test('returns "Ended" when null', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
        );

        expect(auction.timeRemaining, 'Ended');
      });

      test('returns "Ended" when zero or negative', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 0,
        );

        expect(auction.timeRemaining, 'Ended');
      });

      test('returns days and hours for > 24 hours', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 90000, // 25 hours
        );

        expect(auction.timeRemaining, '1d 1h');
      });

      test('returns hours and minutes for < 24 hours', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 7380, // 2h 3m
        );

        expect(auction.timeRemaining, '2h 3m');
      });

      test('returns only minutes when < 1 hour', () {
        final auction = Auction(
          productId: 1,
          productTitle: 'Test',
          currentPrice: 1000,
          bidsCount: 0,
          endsAt: DateTime.now(),
          timeRemainingSeconds: 1800, // 30 minutes
        );

        expect(auction.timeRemaining, '30m');
      });
    });
  });

  group('AuctionsState', () {
    test('initial state has correct defaults', () {
      final state = AuctionsState();

      expect(state.auctions, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.page, 1);
      expect(state.hasMore, true);
    });

    test('copyWith updates specified fields', () {
      final state = AuctionsState();
      final updated = state.copyWith(isLoading: true, page: 2, hasMore: false);

      expect(updated.isLoading, true);
      expect(updated.page, 2);
      expect(updated.hasMore, false);
      expect(updated.auctions, isEmpty); // unchanged
    });

    test('copyWith preserves unspecified fields', () {
      final auction = Auction(
        productId: 1,
        productTitle: 'Test',
        currentPrice: 1000,
        bidsCount: 0,
        endsAt: DateTime.now(),
      );
      final state = AuctionsState(auctions: [auction], page: 2);
      final updated = state.copyWith(isLoading: true);

      expect(updated.auctions.length, 1);
      expect(updated.page, 2);
      expect(updated.isLoading, true);
    });
  });
}
