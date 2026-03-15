import Testing
@testable import Shunkoku

@Suite("Currency Parsing Tests")
struct CurrencyParsingTests {
    @Test("Parse standard amounts")
    func parseStandardAmounts() {
        #expect(CurrencyFormatters.parseAmount("1,234") == 1234)
        #expect(CurrencyFormatters.parseAmount("¥1,234") == 1234)
        #expect(CurrencyFormatters.parseAmount("￥1,234") == 1234)
        #expect(CurrencyFormatters.parseAmount("1,234円") == 1234)
        #expect(CurrencyFormatters.parseAmount("1234") == 1234)
    }

    @Test("Parse negative amounts")
    func parseNegativeAmounts() {
        #expect(CurrencyFormatters.parseAmount("-1,234") == -1234)
        #expect(CurrencyFormatters.parseAmount("−1,234") == -1234)
    }

    @Test("Display yen formatting")
    func displayYen() {
        let result = CurrencyFormatters.displayYen(1234)
        #expect(result.contains("1,234"))
    }
}

@Suite("Date Parsing Tests")
struct DateParsingTests {
    @Test("Parse standard date formats")
    func parseStandardDates() {
        let date1 = DateFormatters.parseFromOCR("2024/03/15")
        #expect(date1 != nil)

        let date2 = DateFormatters.parseFromOCR("2024年3月15日")
        #expect(date2 != nil)
    }
}

@Suite("Account Category Tests")
struct AccountCategoryTests {
    @Test("Income categories identified correctly")
    func incomeCategories() {
        #expect(AccountCategory.sales.isIncome == true)
        #expect(AccountCategory.miscellaneousIncome.isIncome == true)
        #expect(AccountCategory.travelAndTransportation.isIncome == false)
        #expect(AccountCategory.miscellaneousExpense.isIncome == false)
    }

    @Test("All cases accounted for")
    func allCases() {
        #expect(AccountCategory.allCases.count == 21)
        #expect(AccountCategory.expenseCategories.count == 19)
        #expect(AccountCategory.incomeCategories.count == 2)
    }
}

@Suite("Half-width Kana Conversion Tests")
struct KanaConversionTests {
    @Test("Convert half-width katakana to full-width")
    func convertKana() {
        let result = HalfWidthKanaConverter.toFullWidth("ｶﾌﾞｼｷｶﾞｲｼｬ")
        #expect(result.contains("カ"))
    }
}

@Suite("CSV Export Tests")
struct CSVExportTests {
    @Test("Export format file names")
    func fileNames() {
        #expect(ExportFormat.freee.fileNamePrefix == "freee_import")
        #expect(ExportFormat.yayoi.fileNamePrefix == "yayoi_import")
    }
}

@Suite("Tax Rate Tests")
struct TaxRateTests {
    @Test("Tax rates are correct")
    func rates() {
        #expect(TaxRate.standard.rate == 0.10)
        #expect(TaxRate.reduced.rate == 0.08)
        #expect(TaxRate.exempt.rate == 0.0)
    }

    @Test("Freee tax labels")
    func freeeTaxLabels() {
        #expect(TaxRate.standard.freeeTaxLabelPurchase == "課対仕入10%")
        #expect(TaxRate.reduced.freeeTaxLabelPurchase == "課対仕入8%（軽）")
    }
}
