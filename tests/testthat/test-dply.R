demo_SOBI <- run_ICA(demo_epochs, pca = 10)
demo_tfr <- compute_tfr(demo_epochs,
                        n_freq = 2,
                        n_cycles = 3,
                        foi = c(8, 12),
                        keep_trials = TRUE)

test_that("selection of electrodes and times works as expected", {

  add_col <- function(.data) {
    .data$signals$yoyo <-
      (.data$signals$A5 + .data$signals$A13 + .data$signals$A29) / 3
    .data
    }

  expect_equivalent(select(demo_epochs, A5),
                    select_elecs(demo_epochs, "A5"))

  demo_epochs$signals <- tibble::as_tibble(demo_epochs$signals)
  rownames(demo_epochs$signals) <- NULL
  expect_equivalent(filter(demo_epochs, time >= -.1, time <= .3),
               select_times(demo_epochs, c(-.1, .3)))
  expect_equal(mutate(demo_epochs, yoyo = (A5 + A13 + A29) / 3),
               add_col(demo_epochs))
  expect_equivalent(filter(demo_epochs, epoch <= 10, epoch >= 5),
                    select_epochs(demo_epochs, epoch_no = 5:10))
  expect_equivalent(filter(demo_SOBI, epoch <= 20, epoch >= 15),
                    select_epochs(demo_SOBI, epoch_no = 15:20))
  expect_equivalent(filter(demo_tfr, epoch <= 15, epoch >= 10),
                    select_epochs(demo_tfr, epoch_no = 10:15))
  expect_equivalent(select(demo_SOBI, 1:2),
                    select_elecs(demo_SOBI, 1:2))
  expect_equivalent(filter(demo_tfr, frequency >= 10, frequency <= 30),
                    select_freqs(demo_tfr, c(10, 30)))
})

test_that("filter returns tibble when only 1 channel in data", {
  one_chan <- select(demo_epochs, 1)
  expect_s3_class(filter(one_chan, time > .1)$signals, "data.frame")
})
