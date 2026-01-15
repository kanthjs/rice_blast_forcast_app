# tests/testthat/test-models.R

# Use box to import the function we want to test
box::use(
  app/logic/models[calculate_RcT]
)
# Use testthat for testing
box::use(
  testthat[...]
)

test_that("calculate_RcT calculates temperature factor correctly", {
  # Test edge cases
  expect_equal(calculate_RcT(9), 0)    # Lower bound
  expect_equal(calculate_RcT(35), 0)   # Upper bound
  
  # Test optimal temperature
  # The formula is part1 * (part2^exponent)
  # part1 <- (26 - 9) / (26 - 9) = 1
  # part2 <- (35 - 26) / (35 - 26) = 1
  # exponent <- (35 - 26) / (26 - 9) = 9 / 17
  # result should be 1 * (1 ^ (9/17)) = 1, but due to floating point, it might be slightly off.
  # The function is designed to be 1 at Topt, let's test that
  # It seems the formula has an issue, if Topt is used, part2 is (Tmax - Topt)/(Tmax-Topt) which is 1
  # The original formula is likely slightly different, but let's test the implementation
  # With Topt = 26, the implementation gives 1
  expect_equal(calculate_RcT(26), 1.0) # Optimal temperature
  
  # Test a value between Tmin and Topt
  # For temp = 20:
  # part1 = (20 - 9) / (26 - 9) = 11 / 17
  # part2 = (35 - 20) / (35 - 26) = 15 / 9
  # exponent = (35 - 26) / (26 - 9) = 9 / 17
  # expected = (11/17) * (15/9)^(9/17)
  expected <- (11/17) * (15/9)^(9/17)
  expect_equal(calculate_RcT(20), expected)
  
  # Test with a vector of temperatures
  temps <- c(5, 15, 26, 30, 40)
  results <- calculate_RcT(temps)
  
  expected_results <- c(
    0,
    ( (15-9)/(26-9) ) * ( ((35-15)/(35-26)) ^ ((35-26)/(26-9)) ),
    1.0,
    ( (30-9)/(26-9) ) * ( ((35-30)/(35-26)) ^ ((35-26)/(26-9)) ),
    0
  )
  
  expect_equal(results, expected_results, tolerance = 1e-6)
})
